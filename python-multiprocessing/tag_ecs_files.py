#!/usr/local/bin/python3

#####################
# This script syncs all the files from S3 to local
# then syncs all the files up to ECS with the proper meta data (file type)
# It then syncs the files back down to local from ECS
# and does a compare of the two sets of files to ensure they're the same...no changes were made during migration



# This script gets a list of all the files in the requested folder
# it then finds the meta data file type for each file and produces a map grouping each file name by file type
# It then syncs all the files in each group. We do it this way because the sync process only supports single content-types (aka file types)
# which is needed for appropriate classification when the user consumes the files through a browser.
# TODO: Add md5 hashing of each file during upload, then post synchronization do another md5 hash of the files to ensure they're identical.
# TODO: store this md5 hash map somewhere for future validation the files haven't been altered.
#####################


import os
import sys
import getopt
import subprocess
import magic
import boto3
import datetime
import threading
import time
from prettyprinter import pprint
from botocore.config import Config
from multiprocessing import Pool
from pathlib import Path

def getArgs():
    # get the command line arguments
    global iamSerial
    global tokenCode
    global env
    global home

    home = os.getcwd()+"/"

    try:
        opts, args = getopt.getopt(sys.argv[1:],"",["iamSerial=","tokenCode=","env="])
    except getopt.GetoptError:
        print('test.py --iamSerial <iamSerial> -tokenCode <tokenCode>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('test.py -iamSerial <iamSerial> -tokenCode <tokenCode>')
            sys.exit()
        elif opt in ("--iamSerial"):
            iamSerial = arg
        elif opt in ("--tokenCode"):
            tokenCode = arg
        elif opt in ("--env"):
            env = arg

def prepEnv():
    def makeDataFolder(value):
        if not os.path.exists(value):
            try:
                os.makedirs(value)
            except OSError as e:
                if e.errno != errno.EEXIST:
                    raise

    makeDataFolder(env+"/sbg")
    makeDataFolder(env+"_ecs/sbg")
    makeDataFolder(env+"_sorted")

def syncFromS3(iamSerial, tokenCode, env):
    print("*** syncFromS3")
    # obtain the temporary credentials (use the correct MFA token from your virtual device) and token-code
    # Can't use the CLI version as it doesn't output in a script friendly way.  So using boto3 to obtain the temp creds
    # TODO: the profile has previously been defined and hard coded here.  This should be a param?

    # create and change profile
    session = boto3.session.Session(profile_name='ntt-sbrg')
    boto3.setup_default_session(profile_name='ntt-sbrg')

    # used for debugging
    # profiles=boto3.session.Session().available_profiles
    # print(profiles)
    # s3 = boto3.resource('s3')
    # for bucket in s3.buckets.all():
    #     print(bucket.name)

    # commandline method of getting credentials - works manually, but not through scripting
    #bashCommand = "aws sts get-session-token --serial-number "+iamSerial+" --token-code "+tokenCode+" --profile ntt-sbrg"
    #awsCredentials = os.system(bashCommand)

    client = boto3.client('sts')
    awsCredentials = client.get_session_token(
        SerialNumber=iamSerial,
        TokenCode=tokenCode
    )

    # print(awsCredentials)

    # The output of this command are temporary credentials that look like this:
    #     *** returns ***
    # {
    #     "Credentials": {
    #         "AccessKeyId": "ASIA[REDACTED]6H4A",
    #         "SecretAccessKey": "IHZ4[REDACTEDCnvq",
    #         "SessionToken": "IQoJ[REDACTED]7kh9",
    #         "Expiration": "2021-04-07T04:41:16+00:00"
    #     }
    # }

    # we'll start a new session with the MFA credentials just passed back to us:
    # TODO: It's possible the script will take so long to run that the temp creds will expire. Possible fix for this would be to have a "awsCommand" procedure that would validate the credential was good before executing, and if not, then re-run this procedure to update the creds
    # boto3.setup_default_session(
    #     profile_name = "ntt-sbrg-mfa",
    #     aws_access_key_id = awsCredentials['Credentials']['AccessKeyId'],
    #     aws_secret_access_key = awsCredentials['Credentials']['SecretAccessKey'],
    #     aws_session_token = awsCredentials['Credentials']['SessionToken']
    # )

    # print(boto3.client('sts').get_caller_identity().get('UserID'))

    # The boto3 doesn't have a sync method...so we'll have to fallback to the cli version that AWS provides.

    # Todo that we'll need to export the token and keys to the environment for the CLI to leverage for the sync.
    os.environ['AWS_ACCESS_KEY_ID'] = awsCredentials['Credentials']['AccessKeyId']
    os.environ['AWS_SECRET_ACCESS_KEY'] = awsCredentials['Credentials']['SecretAccessKey']
    os.environ['AWS_SESSION_TOKEN'] = awsCredentials['Credentials']['SessionToken']

    # IMPORTANT: I'm logging this portion of the process because the output needs additional processing due to the "multi-slash issue". See the DB migration notes for additional info
    bashCommand = "aws s3 sync s3://"+env+"-bcrg/ ./"+env+"/sbg/ | tee "+env+"_s3_sync_files.log"
    # print(bashCommand)
    os.system(bashCommand)

def getFileList():
    print("*** getFileList")

    # get a list of all the files
    os.chdir(home+env)
    file_list = subprocess.run(['find', '.','-type','file'], stdout=subprocess.PIPE).stdout.decode('utf-8')[:-1]
    files_array = file_list.split('\n')

    return files_array

def getMetaData(files):
    #obtains the meta file type for each file and sorts the files into a map with the metatype as the key
    print("*** getMetaData")


    def add_values_in_dict(typedict, key, value):
        if key not in typedict:
            typedict[key] = list()

        # the aws sync command doesn't like the ./ in the include param of the filename.  So we need to strip that out from the values returned by the find command
        value = value[2:]

        # the --include will be used in the syncFilesToECS to filter which files should be synced based on meta_type.  Adding it here now to save looping through the list again later on.
        #typedict[key].append(" --include '"+value+"'")
        typedict[key].append(value)
        return typedict

    files_dict = dict()

    os.chdir(home+env)
    i = 0
    count = len(files)
    for filename in files:
        i += 1
        print("%s of %s" % (i, count), end='\r')
        mime = magic.from_file(filename, mime=True)
        files_dict = add_values_in_dict(files_dict, mime, filename)

    # print (files_dict)

    return files_dict


def rsyncMetaType(filenames, home, env, meta_folder):

    os.chdir(home+env)

    for filename in filenames:
        bashCommand = "rsync -aP --quiet --inplace --log-file="+home+env+"_rsync_metatypes.log --link-dest="+filename+" --relative "+filename+" ../"+env+"_sorted/"+meta_folder
        # os.system(bashCommand)
        p = subprocess.Popen(bashCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        p.wait()
        # print("******* BashCommandis: "+bashCommand)


def preSortFilesByMetaType_Mapping(files_dict):
    print("*** preSortFilesByMetaType")

    os.chdir(home+env)

    # This step isn't optimal.  We need to look at each file individually and sync it to the properly sorted location.
    # This sucks because even if the file is already been sorted in a previous run we do it again.
    # TODO: make a list of existing files in the pre-sorted folder and don't rsync them again.  This should optimize the process a great deal.
    meta_data = []

    for meta_type, filenames in files_dict.items():
        # For each of the meta_types we'll kick off an rsync on each file to copy it into a pre-sorted folder.  This process will drastically speed up the sync process when it's time to send to ECS
        # print(key, '->', value)
        # print(value)
        print(meta_type)  # Key is the meta_type

        meta_folder = meta_type.replace("/","_")
        if not os.path.exists("../"+env+"_sorted/"+meta_folder):
            os.makedirs("../"+env+"_sorted/"+meta_folder)

        # lets run parallel rsyncs in groupings of meta_type.  it'll still run many sequential rsyncs, but it'll still be faster.
        val = filenames, home, env, meta_folder
        meta_data.append(val)


    pool = Pool(8)
    results = pool.starmap(rsyncMetaType, meta_data)
    pool.close()
    pool.join()


def syncECS(meta_type, env, home):
    meta_folder = meta_type.replace("/","_")

    # meta_type_name = meta_type[0]
    # env = meta_type[1]
    # home = meta_type[2]

    print("Syncing type: "+meta_type)
    # x = f'text {metafolder}'
    bashCommand = "aws s3 sync . s3://sbg-"+env+"-enc/ --endpoint-url https://sbg.objectstore.gov.bc.ca --content-type '"+meta_type+"' --profile ntt-ecs-"+env+" >> "+home+env+"_ecs_sync.log"
    os.chdir(home+env+"_sorted/"+meta_folder)
    # os.system(bashCommand)
    p = subprocess.Popen(bashCommand, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    p.wait()
    # print("******* BashCommandis: "+bashCommand)

def syncMetaTypesToECS_Mapping(files_dict):
    print("*** syncMetaTypesToECS_Mapping")

    meta_types = []
    for key, value in files_dict.items():
        val = key, env, home
        meta_types.append(val)

    pool = Pool(8)
    results = pool.starmap(syncECS, meta_types)
    pool.close()
    pool.join()

def syncFromECS():
    print("*** syncFromECS")
    bashCommand = "aws s3 sync s3://sbg-"+env+"-enc/ . --endpoint-url https://sbg.objectstore.gov.bc.ca --profile ntt-ecs-"+env
    os.chdir(home+env+'_ecs')
    os.system(bashCommand)

def diffS3ToECS():
    print("*** diffS3ToECS")

    print("S3 File Count: ")
    bashCommand = "find "+env+" -type f |wc -l"
    os.chdir(home)
    os.system(bashCommand)

    print("Meta-type Sorted File Count: ")
    bashCommand = "find "+env+"_sorted -type f |wc -l"
    os.chdir(home)
    os.system(bashCommand)

    print("ECS File Count: ")
    bashCommand = "find "+env+"_ecs -type f |wc -l"
    os.chdir(home)
    os.system(bashCommand)

    # produce an md5 from s3 source
    bashCommand = "find . -type f -exec md5sum '{}' \; > ../../"+env+"_hash.md5"
    # os.chdir(home+env+"/sbg/")
    print("Starting S3 MD5 Hashing: %s" % datetime.datetime.now().time())
    tic = time.perf_counter()
    # os.system(bashCommand)
    toc = time.perf_counter()
    print(f"Hashing took {toc-tic:0.4f} seconds")

    # Test the MD5 check is working to report anomalies
    # bashCommand = "rm -rfv dev_ecs/sbg/08461b6a-9cf5-4589-9022-3bf41fd9bf1a/QO3dfu9wDx8IppqYawVOpwI2OtghzN0LSAelURVYFmk="
    # os.system(bashCommand)

    # compare that produced hash list against the files downloaded from ECS
    # Note the --quiet is to squash OK output, will only show differences if any.
    bashCommand = "md5sum -c ../../"+env+"_hash.md5 --quiet"
    print("Starting ECS MD5 Check %s" % datetime.datetime.now().time())
    os.chdir(home+env+"_ecs/sbg/")
    tic = time.perf_counter()
    print("MD5 Check Return code: %s" % os.WEXITSTATUS(os.system(bashCommand)))
    toc = time.perf_counter()
    print(f"MD5 Check took: {toc-tic:04f} seconds")



def main():
    # acquire the command line arguments
    getArgs()

    # setup the local env to have the proper directory tree
    prepEnv()

    # sync all the files down from s3
    syncFromS3(iamSerial, tokenCode, env)

    # get all the filenames that were synced from S3
    files = getFileList()

    # retreive the mata data from each of those files
    files_dict = getMetaData(files)

    # move files from S3 source location to meta_type mirror location grouping all files of the same meta_type together
    # WHY? This eliminates the filtering that was previously done which is a massive bottleneck due to the way it was implemented and the way we tried to used it.
    preSortFilesByMetaType_Mapping(files_dict)

    # sync each of the meta_type mirrors to ECS (in parallel?)
    # syncMetaTypesToECS(files_dict)    # works at around 2:50 but I think we make this faster by parallel processing
    # syncMetaTypesToECS_MultiThreading(files_dict)     # can't get this to work.  Not all files are uploaded to ECS! Works differently on each consecutive run
    syncMetaTypesToECS_Mapping(files_dict)

    # sync the files up to ECS
    # p = Pool(5)
    # p.map(syncFilesToECS_Pool, files_dict)
    # syncFilesToECS(files_dict)

    # sync back down from ECS
    syncFromECS()

    #md5 compare the files between the two folders
    diffS3ToECS()

if __name__ == '__main__':
    main()
