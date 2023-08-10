from kubernetes import client, config
from flask import Flask
from os import environ
import logging

app = Flask(__name__)

@app.route('/midas/touch')
def check_services():
    logging.basicConfig(format='%(message)s', level=logging.INFO)

    namespace = environ['namespace']
    cluster = environ['cluster']

    # this is the magic to connect to the OCP cluster for running kubernetes commands
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise Exception("Could not configure kubernetes python client")

    v1 = client.CoreV1Api()
    output = f'<div>cluster - <font style="color:#ffd700;">{cluster}</font></div>'
    success = True

    # need to loop though service_list.items to collect metadata.name
    try:
        service_list = v1.list_namespaced_service(namespace, label_selector="midas=touch")
        for service in service_list.items:
            # for each service we check if there's either an IP address (couple conditions on that check). If no IP, it's a fail.
            try:
                # print(f"Checking service: {service.metadata.name}")
                endpoints = v1.read_namespaced_endpoints(service.metadata.name, namespace)
                if not endpoints.subsets or not endpoints.subsets[0].addresses:
                    success = False
                    output += f'<div>{service.metadata.name}<font style="color:red;"> - FAILED</font></div>'
                    logging.info(f'{service.metadata.name} FAILED')
                else:
                    output += f'<div>{service.metadata.name}<font style="color:green;"> - OK</font></div>'
                    logging.info(f'{service.metadata.name} OK')
            except ApiException as e:
                print(f"Error retrieving endpoints: {e}")
                return 'FAIL - Error retrieving endpoint: {e}', 500
    except ApiException as e:
        print(f"Failed getting service list: {e}")
        return 'FAIL - Failed getting service list', 500

    # this is to override the actual "success" results.
    # debugging was added to force a 200 when true (500 when false) to allow for easier debugging of the networking
    try:
        notouch = environ['notouch']
        if notouch == "200":
            output += '<div>Return Code: <font style="color:green;">200</font></div>'
            return output, 200
        elif notouch == "500":
            output += '<div>Return Code: <font style="color:red;">500</font></div>'
            return output, 500
    except KeyError:
        pass

    # This is the happy path if notouch isn't set.
    if success:
        output += '<div>Return Code: <font style="color:green;">200</font></div>'
        return output, 200
    else:
        output += '<div>Return Code: <font style="color:red;">500</font></div>'
        return output, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
