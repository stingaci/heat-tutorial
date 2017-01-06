================================================
Software Orchestration with Software Deployments 
================================================

This portion of the tutorial focuses on using a different software 
orchestration engine, namely Heat Software Deployments. This orchestration 
engine allows for stack update operations on software configuration resources 
without the need to redeploy instances associated with those software 
configurations, effectively allowing for the management of an instance throughout 
its full lifecycle. 

In order to employ Heat Software Deployments, the image that's used to run the 
instance must have a number of agents namely:  os-collect-config, 
os-apply-config, and os-refresh-config. Their job is to coordinate the reading, 
running, and updating of the software configuration that will be sent via Heat. 
The following exercises assume that these agents don't exist on the image the 
reader will be using. Ideally, these agents would be built in to the image that 
you would use in a production environment. 

In order to use Software Deployments, these agents must be installed when the 
instance starts up and thus cloud-init will be used to do so. The Heat 
community have built the cloud-init scripts to install these agents for 
different operating systems and they can be found in the heat-templates github 
repo under the `boot-config 
<https://github.com/openstack/heat-templates/tree/master/hot/software-config/boot-config>`_ 
directory. The lib directory in this tutorial contains a slightly modified version 
of the boot-config directory within the heat-templates repo to allow for 
setting an http proxy as well as some Liberty specific configuration (note 
these changes have only been applied for the centos7_rdo_env.yaml environment). 
The details of the installation and configuration of each particular agent is 
outside of the scope of this tutorial. Instead, this tutorial will focus on how 
to use cloud-init to install these agents and how to use Software Deployments 
to leverage these agents. 

The reader is strongly encouraged to read the `Heat Software Deployments 
<http://docs.openstack.org/developer/heat/template_guide/software_deployment.html#software-deployment-resources>`_ 
documentation alongside this tutorial. 

This would also be an appropriate time to quickly overview the stack update 
command. It is very important to note that an update of a stack will only perform 
an actual update if one or more resources have been modified within the 
template (this also includes input parameters and any change in an input 
parameter will affect all resources referencing this particular input 
parameter). This may an be an obvious point to the reader, however it is an 
important reminder before continuing to understand SoftwareDeployments. 


Prerequisites
============

This portion of the tutorial requires a network, a router, a subnet, and two
security groups.

Setup
=====

The reader can either choose to deploy their own prerequisite resources or they
can use the setup.yaml stack definition to automatically do so.  The setup file
can be deployed as follows:

.. code:: bash

  $ openstack stack create -t setup.yaml --parameter public_network_id=$PUBLIC_NETOWRK_ID setup
  

Training Templates
==================

ex5.1.yaml
-----------

This template introduces the basics of using Software Deployments to install 
and configure a webserver

**Notes**

The reader will notice two new resource types in this template. Let's first 
focus on the *Heat::InstallConfigAgent*. This resource is actually defined 
within the environment file *env.yaml* and points to the following file 
*lib/boot-config/templates/install_config_agent_centos7_rdo.yaml*. This file 
contains the necessary cloud-init scripts to install the agents required to use 
Software Deployments. As previously mentioned, the details of those scripts 
will not be covered here. The reader should notice that the user_data property 
of the *instance* resource uses the *boot_config* resource. Up until this 
point, there should not be anything new to the reader. 

Same as before, this template also contains a Software Config resource that 
installs, configures and starts a webserver. The only difference lies in the 
*group* attribute. Heat Software Deployments support different types of hooks 
for software configurations such as bash scripts, puppet scripts, etc via the 
group attribute of the SoftwareConfiguration resource. The reader is encouraged 
to check out the full list of supported `Software Configuration Hooks 
<https://github.com/openstack/heat-templates/tree/master/hot/software-config/elements>`_. 
In this tutorial we will only use the scripts hooks.

Lastly, the *http_deployment* resource definition is of type 
`OS::Heat::SoftwareDeployment 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::SoftwareDeployment>`_ 
and looks as follows:

.. code:: yaml

  http_deployment:
    type: OS::Heat::SoftwareDeployment
    properties:
      config: { get_resource: http_config }
      server: { get_resource: instance }
      signal_transport: HEAT_SIGNAL
      actions:
        - CREATE
        - UPDATE

Relevant to this part of conversation, the instance also has two properties 
that are now different:

.. code:: yaml

    user_data_format: SOFTWARE_CONFIG
    software_config_transport: POLL_SERVER_HEAT

This OS::Heat::SoftwareDeployment resource associates a 
OS::Heat::SoftwareConfig resource with an OS::Nova::Server as specified by the 
*config* and *server* property of the *http_deployment* resource. A Software 
Deployment uses the aforementioned agents to send the configuration metadata to 
the instance via a transport mechanism specified by the 
`software_config_transport 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Nova::Server-prop-software_config_transport>`_ 
attribute of OS::Nova::Server resource. The reader is encouraged to determine 
the appropriate *software_config_transport* for their envrioment as it depends on 
how Heat was deployed as well as their public networking configuration. Also 
whenever the instance uses software deployments the *user_data_property* should 
be set to SOFTWARE_CONFIG to indicate the instance status will be updated via 
SoftwareDeployment resources.

The `signal_transport 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::SoftwareDeployment-prop-signal_transport>`_ 
attribute of the OS::Heat::SoftwareDeployment resource specifies which signal 
transport mechanism the instance associated with this Software Deployment 
should use to let Heat know it finished with this software deployment. Akin to 
the *software_config_transport*, the reader is encouraged to determine the 
appropriate value for their environment. 

Lastly, the *actions* attribute of the OS::Heat::SoftwareDeployment resource 
indicates which lifecycle actions of the deployment resource will result in 
this deployment being triggered. This means you can have Software Deployments 
only when an instance is created, or only when it is deleted (DELETE), or only 
on a stack update (UPDATE). The default value is CREATE and UPDATE. 

To summarize, the instance spawns and uses the Heat::InstallConfigAgent 
software configuration via the instance *user_data* attribute to install the 
required agents to use Heat Software Deployments. When these agents startup 
they use the transport mechanism specified by the *software_config_transport* 
attribute of the instance to gather the metadata of the software deployments 
associated with this particular instance. At this point, all 
OS::Heat::SoftwareDeployment resources associated with this instance as well as 
the instance are in a *CREATE_IN_PROGRESS* state. The instance then use the 
metadata to actually gather and apply the software configuration associated 
with each software deployment resource. After it applied the software 
configuration, the instance will use the signal mechanism specified by the 
*signal_transport* attribute of each software deployment and signal to Heat so 
that it can mark the SoftwareDeployment resource as *CREATE_COMPLETE*. When all 
SoftwareDeployment resources that are associated with the instance are in a 
*CREATE_COMPLETE* state, the instance also achieves a state of 
*CREATE_COMPLETE*. 

This means that unlike with cloud-init, the user is no longer responsible for 
performing the signaling manually. This first template may seem 
over-complicated for what we already managed to achieve earlier in this 
tutorial, however the advantages of Software Deployments will become apparent 
in later exercises.  

Upon successful deployment, the user should be able to run the following:

.. code:: bash

  curl <instance_floating_ip> 

and return 

.. code:: text

  Hello World!

**Deployment**

This template can be deployed as follows:

.. code:: bash

  $ os stack create -t ex5.1.yaml -e env.yaml ex5.1


ex5.2.yaml
----------

This exercise aims to illustrate how a webserver application template can be 
built using Software Deployments 

**Notes**

The main template should be nothing new to the reader. We are using a resource 
of type *Tutorial::Application::HTTP* which resolves to the 
*lib/applications/httpd.yaml* file. The reader familiar with partIV of this 
tutorial will notice the only difference in this file is the *boot_config* 
resource which is associated with the *user_data* attribute of the instance 
defintion and installs the required agents on the webserver instance. 

Also, instead of passing the *http_config* resource to the *user_data* 
attribute, we instead pass on the instance to the *http_config* resource like 
so:

.. code:: yaml

  http_config:
    type: ../softwareconfigs/httpd.yaml
    properties:
      msg: { get_param: message }
      instance: { get_resource: instance }


Within the *../softwareconfigs/httpd.yaml*, the reader will notice six resource 
definitions; two (instead of one like when using cloud-init) for each stage of 
the webserver deployment. Each pair has an *OS::Heat::SoftwareConfig* resource 
which stores the configuration, and a *OS::Heat::SoftwareDeployment* resource 
which associates the SoftwareConfig resource with the instance. Do note that a 
*OS::Heat::SoftwareDeployment* can *not* be associated with more than one 
SoftwareConfig resource and it also can not be associated with a 
*OS::Heat::MultipartMime* resource type either. 

Let's go over each of these stages, starting with the installation stage:

.. code:: yaml

  http_install:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      config: { get_file: scripts/httpd/install.sh }

  http_install_deployment:
    type: OS::Heat::SoftwareDeployment
    properties:
      config: { get_resource: http_install }
      server: { get_param: instance }
      signal_transport: HEAT_SIGNAL
      actions:
        - CREATE 

This is a very similar SoftwareDeployment to the previous exercise. The only 
important thing to note is the lack of an *UPDATE* action in the *actions* 
attribute of the SoftwareDeployment resource. This makes sense, as this script 
should only run when the instance is first created. 

The next stage is the configuration stage:

.. code:: yaml

  http_configure:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      config:
        str_replace:
          params:
            $msg: { get_param: msg }
          template: { get_file: scripts/httpd/configure.sh }

  http_configure_deployment:
    type: OS::Heat::SoftwareDeployment
    depends_on:
      - http_install_deployment
    properties:
      config: { get_resource: http_configure }
      server: { get_param: instance }
      signal_transport: HEAT_SIGNAL
      actions:
        - CREATE
        - UPDATE

The SoftwareConfiguration resource should already familiar to the reader. This 
configuration can be run when stack is created as well as when stack is 
updated. As mentioned in the introductory paragraph, a stack update command 
will only trigger the *http_configure* script to run if something has changed, 
for example the *msg* parameter or a change in the script. If the stack update 
command is run with the same exact configuration as the stack create command, 
the *http_configure* script will *not* run again. 

Another very important point to mention here is in regards to the *depends_on* 
attribute of the *http_configure_deployment* resource. While using cloud-init, 
we had three *OS::Heat::SoftwareConfig* resources and at the end combined them 
using a *OS::Heat::MultipartMime* resource type where the order in which they 
were defined was the order in which they were executed. While using a 
*OS::Heat::SoftwareDeployment* resource, each *OS::Heat::SoftwareConfig* is 
directly associated with an instance and thus no order is guaranteed. The 
*depends_on* attribute enforces this order by marking the 
*http_install_deployment* resource as a prerequisite of the 
*http_configure_deployment* resource. 

Lastly, the service startup stage is quite similar to the installation stage 
and should only be run when the instance is created:

.. code:: yaml

  http_start:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      config: { get_file: scripts/httpd/start.sh }

  http_start_deployment:
    type: OS::Heat::SoftwareDeployment
    depends_on:
      - http_configure_deployment
    properties:
      config: { get_resource: http_start }
      server: { get_param: instance }
      signal_transport: HEAT_SIGNAL
      actions:
        - CREATE

Similar to the previous stage, the *depends_on* attribute is used to mark the 
*http_configure_deployment* as a prerequisite for this stage. 

The reader is encouraged to deploy a stack using this template as well as 
update the stack and verify that the instance was not rebooted. In order to do 
so, the user should use the following message as an input parameter:

.. code:: bash

  --parameter message="Action Create \`uptime\`"      (when creating the stack)
  --parameter message="Action Update \`uptime\`"      (when updating the stack)

The uptime command in the msg will validate that the instance was not rebooted 
on a stack update command. 

**Deployment**

This stack can be created as follows:

.. code:: bash
 
  $ openstack stack create -t ex5.2.yaml -e env.yaml ex5.2 --parameter message="Action Create \`uptime\`"

and the stack can be updated as follows

.. code:: bash

  $ openstack stack update -t ex5.2.yaml -e env.yaml ex5.2 --parameter message="Action Update \`uptime\`"

ex5.3.yaml
----------

This exercise showcases that SoftwareDeployment resources do not require manual 
signaling like when using cloud-init as a software orchestration engine

**Notes** 

Upon opening this file, the reader should notice, this template is the exact 
same template as ex4.6.yaml which showed that while creating dependencies 
between resources when using cloud-init, explicit signaling is required by user 
via the use of the *OS::Heat::WaitCondition* and 
*OS::Heat::WaitCondtionHandle** resources. This exercise showcases that this 
not required while using SoftwareDeployments. 

Upon the successful deployment of this template the user can check the contents 
of /tmp/hello file on the *instance* resource defined in the main template as 
follows:

.. code:: bash

  $ ssh -i ../key-pairs/heat_key centos@<instnce_floating_ip> "cat /tmp/hello"

And the resulting output should be:

.. code:: text

  Data gathered from http: Webservers are awesome!

ex5.4.yaml
----------

This template show cases a more realistic use of SoftwareDeployments as well as 
how SoftwareDeployments can be used to gather the output from SoftwareConfig 
scripts. 

**Notes** 

The reader will notice a SoftwareConfig resource that is associated with the 
http instance that looks as follows:

.. code:: yaml

  config:
    type: OS::Heat::SoftwareConfig
    properties:
      group: script
      inputs:
        - name: mode
      outputs:
        - name: result
      config: |
        #!/bin/bash -ax
        if [ $mode = "init" ];
        then
          # The server is initlized
          echo "Webserver is initlized" > /var/www/html/index.html
          echo "Succesfully initlized server" > $heat_outputs_path.result
        elif [ $mode = "dev" ];
        then
          # You can gather data from a specific git branch:
          # git clone url-to-rep
          # git checkout dev 
          echo "This server is running in dev mode" > /var/www/html/index.html
          echo "Succesfully switched server to dev mode" > 
          $heat_outputs_path.result
        elif [ $mode = "prod" ];
        then
          # git clone url-to-repo
          # git checkout prod
          echo "This server is running in prod mode" > /var/www/html/index.html
          echo "Succesfully switched server to prod mode" > 
          $heat_outputs_path.result
        else
          echo "Failed to update server. Invalide mode parameter" > 
          $heat_outputs_path.result
        fi

The config script contains three if statements, one for the init stage, one for dev 
and another for prod. As specified by the comments, a git repo can be used and 
the current $mode can be used to switch between different branches (ie. 
dev/prod) of the repo. In this exercise, this is simulated with the use of of 
*echo* commands. The reader will also notice two new properties, namely inputs 
and outputs. The inputs section directly map to the *input_values* attribute of 
the SoftwareDeployment resource, in this case:

.. code:: yaml

      input_values:
        mode: { get_param: server_mode }


While the outputs section declares any number of output variables that can be 
used throughout the script in the form of 
*$heat_outputs_path.<OUTPUT_VAR_NAME*, in this case: 
*$heat_outputs_path.result*. This variable can then later be extracted in the 
*outputs* section of the template as an attribute of the SoftwareDeployment 
resource that's associated with this SoftwareConfig resource. The 
SoftwareDeployment resource also has the *deploy_stdout* and *deploy_stderr* 
attributes for the script within the SoftwareConfig and thus the outputs 
section in this template looks as follows:

.. code:: yaml

  outputs:
    http_ipaddr:
      value: { get_attr: [ http_floating_ip, floating_ip_address ] }
    result:
      value: { get_attr: [deployment, result] }
    std_out:
      value: { get_attr: [deployment, deploy_stdout] }
    std_err:
      value: { get_attr: [deployment, deploy_stderr] }

The *-ax* switch in the script shebang will ensure output in deploy_stderr 
as the script is run is debug mode. 

**Deployment**

The stack can be created using:

.. code:: bash

  $ openstack stack create -t ex5.4.yaml -e env.yaml ex5.4 --parameter 
  server_mode=init

It can be updated to dev using:

.. code:: bash

  $ openstack stack update -t ex5.4.yaml -e env.yaml ex5.4 --parameter 
  server_mode=dev

And it can be updated to prod using:

.. code:: bash

  $ openstack stack update -t ex5.4.yaml -e env.yaml ex5.4 --parameter 
  server_mode=prod

**Extras**

In all of these exercises, we have had a *configuration* section where we 
initialize index.html to some message for the webserver application template. 
In a more realistic environment, the webserver configuration section would 
actually contain a configuration file (ie. httpd.conf, sites-available/conf, 
etc) and a SofwareDeployment can be used to inject whatever content the 
webserver should serve at runtime. Similar to this exercise. 
