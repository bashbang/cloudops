#!/python

# This script is the heart of the midas dashboard.
# it runs a webserver (flask) and returns a dashoboard or JSON output
# The dashboard is generated by connecting to the Openshift cluster and getting a list of services with the tag midas=touch
# It then probes each service to see it's current status. If there's a pod associated to the service then it's "OK", otherwise it will "FAIL"

from kubernetes import client, config
from flask import Flask
from os import environ
import requests
import logging

app = Flask(__name__)

def check_services(output_type):
    logging.basicConfig(format='%(message)s', level=logging.INFO)

    namespace = environ.get('namespace')
    cluster = environ.get('cluster')
    notouch = environ.get('notouch')
    data = {}

    # this is the magic to connect to the OCP cluster for running kubernetes commands
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise Exception("Could not configure kubernetes python client")

    v1 = client.CoreV1Api()
    data['cluster'] = cluster
    output = f'<div>cluster - <font style="color:#ffd700;">{cluster}</font></div>'
    success = True
    return_code = "200"

    # need to loop though service_list.items to collect metadata.name
    try:
        service_list = v1.list_namespaced_service(namespace, label_selector="midas=touch")
        for service in service_list.items:
            # for each service we check if there's either an IP address (couple conditions on that check). If no IP, it's a fail.
            try:
                print(f"Checking service: {service.metadata.name}")
                endpoints = v1.read_namespaced_endpoints(service.metadata.name, namespace)
                if not endpoints.subsets or not endpoints.subsets[0].addresses:
                    success = False
                    data[service.metadata.name] = 'FAILED'
                    return_color = "red"
                else:
                    data[service.metadata.name] = 'OK'
                    return_color = "green"

                output += f'<div>{service.metadata.name}<font style="color:{return_color};"> - {data[service.metadata.name]}</font></div>'
                logging.info(f'{service.metadata.name}: {data[service.metadata.name]}')

            except Exception as e:
                print(f"Error retrieving endpoints: {e}")
                return 'FAIL - Error retrieving endpoint: {e}', 500

        if success:
            return_color = "green"
        else:
            return_code="500"
            return_color = "red"

        # this is to override the actual "success" results.
        # debugging was added to force a 200 when true (500 when false) to allow for easier debugging of the networking
        if  notouch == "200":
            return_color = "green"
        elif notouch == "500":
            return_code = "500"
            return_color = "red"

        data["return_code"] = return_code
        output += f'<div>Return Code: <font style="color:{return_color};">{return_code}</font></div>'

        if output_type == "json":
            output = data
        return output, return_code

    except Exception as e:
        print(f"Failed getting service list: {e}")
        return 'FAIL - Failed getting service list', 500

@app.route('/midas/touch')
def output_html():
    output, return_code = check_services("html")
    return output, return_code

@app.route('/midas/json')
def output_json():
    output, return_code = check_services("json")
    return output, return_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
