================================================================
Software Orchestration with Cloud-init and Heat SoftwareConfigs
================================================================

Up until this point of the tutorial, we've only managed to orchestrate 
infrastructure resources (ie. instances, networks, floating IPs, etc). This 
portion of the tutorial aims to introduce cloud-init and Heat software configs 
which can be used to orchestrate the instance at software layer (ie. install 
packages, add users, inject configuration, etc). By the end of this part of the 
tutorial the reader should be able to launch an instance and perform any number 
of configurations at boot time within this instance as well as utilize the Heat 
signaling mechanism to report a more accurate status for stack resources (and 
thus create more accurate dependencies). 

The reader completely unfamiliar with cloud-init should spend some time 
browsing through the `official documentation 
<https://cloudinit.readthedocs.io/en/latest/>`_. 

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

ex4.1.yaml
---------------
  
This template introduces the basics of using cloud-init in order to orchestrate 
a "Hello world" example. 

**Notes**

In order to supply the instance with a configuration (ie. a script) the 
user_data property of the OS::Nova:Server resource definition is used. Along 
side the user_data property, the user_data_format is also set to RAW. Whenever 
using cloud-init, the user_data_format must be set to RAW (more on different 
values for the user_data_format later). The script inside the user_data 
property is a simple script that prints "Hello world" to the /tmp/help file 
(the '|' is a YAML `literal sytle block chomping indicator 
<http://www.yaml.org/spec/1.2/spec.html#id2795688>`_ used to indicate the 
following text is multiline input which preserves new lines). 

After launching this stack, the reader can check if the user_data script has 
successfully ran by running the following command:

.. code:: bash
  
  $ ssh -i <heat_key path> <user>@<instance ip> cat /tmp/hello``

"Hello world!" should print out in your terminal. 

The reader should also notice that the stack status is not dependent on the 
success or failure of the cloud-init script nor is it dependent on its 
completion. As soon as the instance is spawned and becomes active, the resource 
status will become *CREATE_COMPLETE*. This means that even though the stack has 
launched successfully, *cloud-init* may still be in the process of applying the 
user-data script. The user can monitor the instance console log (and thus the 
cloud-init output) via the following command:

.. code:: bash
 
  $ opensatack console log show <instance name/id>

For further cloud-init debuging the user can check the `/var/lib/cloud folder 
<http://cloudinit.readthedocs.io/en/latest/topics/dir_layout.html>`_  or 
/var/log/cloud-init.log file on the instance. 

**Deployment**

This stack can be created using the following command:

.. code:: bash

  openstack stack create -t ex4.1.yaml -e env.yaml ex4.1


ex4.2.yaml
---------------

This template uses the previously introduced *str_replace* intrinsic function 
to provide the script defined in user_data with inputs that the user will 
provide as parameters when the stack is created. 

**Notes** 

The format for the *str_replace* function should be familiar to the reader by 
now. The two input parameters: output_string and output_file can now be used to 
control the result of the user_data script. The reader can validate this 
functionality by launching the stack with the default values or custom values 
and verify the output file in the same manner as the previous exercise. 

**Deployment**

This stack can be created using the following command:

.. code:: bash

  openstack stack create -t ex4.2.yaml -e env.yaml ex4.2


ex4.3.yaml
---------------

This template introduces the cloud-config script type and uses it to add a 
user, and install & start a webserver 

**Notes**

The first two templates utilized a bash script supplied in the user_data 
property. Cloud-init uses the shebang at the beginning of the script to 
identify which interpreter should be used (ie. bash, python). A special type of 
script named cloud-config is also supported by cloud-init. This script uses the 
YAML format to describe actions to be performed upon instance startup. You can find 
more cloud-config examples on the `cloud_init man pages 
<http://cloudinit.readthedocs.io/en/latest/topics/examples.html>`_. The script 
looks as follows:

.. code:: yaml

  ..
  user_data:
    str_replace:
      template: |
        #cloud-config
        write_files:
          - path: $output_file
            content: $output_string
        users:
          - default
          - name: $user
            sudo: ALL=(ALL) NOPASSWD:ALL
            ssh-authorized-keys:
             - $ssh_key
        packages:
          - httpd
        runcmd:
          - service httpd start
      params:
        $output_string: { get_param: output_string }
        $output_file: { get_param: output_file }
        $user: { get_param: user }
        $ssh_key: { get_file: ../key-pairs/heat_key.pub }
  ..

The structure of str_replace should already be familiar to the reader. The 
template attribute contains four sections, namely: write_files, users, packages 
and runcmd. The write_files section takes a path and some content (exactly like 
the previous two exercises). The users section creates two users: a default 
user (cloud user; for Centos images that is *centos*) and a user whose 
username is supplied as an input parameter, has sudo access with no password 
and has the ssh key that's been used throughout this tutorial. The packages 
section enforces the installation of the *httpd* package and runcmd section 
starts the httpd service.  

As part of this exercise, the *get_file* intrinsic function was used for the 
first time. This function can be used to retrieve the content of a file. This 
file can be specified as a full path, or as an URL (do note that the value for 
this function can not be combined with another intrinsic function like 
get_param for example). 

You can verify the success of the command by attempting to login to the newly 
created instance with the user you created and the ssh key located in 
../key-pair/heat-key. The reader can also validate that the httpd service is 
running the following:

.. code:: bash

  $ curl <instance floating ip> 

This should return "Hello world!"

**Deployment**

This stack can be created using the following command:

.. code:: bash

  openstack stack create -t ex4.3.yaml -e env.yaml ex4.3 --parameter user=my_user

**Extras** 

The benefit of using *cloud-config* scripts over regular bash scripts has to do 
with OS compatibility. Cloud-init will determine the type of OS that is running 
on the image and perform the requested operation native to that OS. For 
example, when requesting the installation of a package, cloud-init will use the 
package manager native to the OS that's currently running (in the case of 
Centos it will use yum while in the case of Ubuntu it will use apt-get). There 
are also advantages due to the fact that the process of installing a package 
(or any other of the cloud-config sections) is validated by the community 
supporting cloud-init and thus will be less error prone than custom built 
scripts. 


ex3.4.yaml
----------

This template deploys multiple types of software configurations (cloud-config 
and scripts) via the use of Heat::SoftwareConfigs and Heat::MultipartMime

**Notes** 

The first thing the reader should notice is a new type of resource named 
`OS::Heat::SoftwareConfig 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::SoftwareConfig>`_. 
This type of resource allows the user to define a software configuration script 
as an entity that can be later associated with an instance. Take the 
*user_config* resource definition as an example:

.. code:: yaml

  user_config:
    type: OS::Heat::SoftwareConfig
    properties:
      group: ungrouped
      config:
        str_replace:
          template: |
            #cloud-config
            users:
              - default
              - name: $user
                sudo: ALL=(ALL) NOPASSWD:ALL
                ssh-authorized-keys:
                 - $ssh_key
          params:
            $user: { get_param: user }
            $ssh_key: { get_file: ../key-pairs/heat_key.pub }

This definition has two properties, namely group and config. The group property 
specifies which namespace this config will be delivered under to the instance. 
The *ungrouped* value is the default value and should always be used when using 
cloud-init as the software orchestration engine (more on other types of 
groups later). The config section, as the name indicates, holds the actual 
configuration for this resource definition. The reader will notice this is a 
cloud-config type of script containing the users section from previous exercises. 

Another OS::Heat::SoftwareConfig resource, namely *http_config*, has been 
defined in this template which is used to install, configure and start a 
webserver (similar to previous exercises). The more important point to notice 
here is that the *user_config* software config has a template script of type 
cloud-config, while *http_config* has a template script of type #/bin/bash. 
Cloud-config uses the `MIME protocol <https://en.wikipedia.org/wiki/MIME>`_ to 
combine scripts of different types. In order to combine multiple SoftwareConfig 
resources into one ordered config, the `OS::MultipartMime 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::MultipartMime>`_ 
resource is used. 

It's important to note that the order in which each SoftwareConfig is specified 
in the MultipartMime 'parts' attribute is the order they will be executed in. 
Lastly, the user_data attribute of the instance is used to reference the 
MultipartMeme resource via the *get_resource* intrinsic function. 

Upon successful deployment, the reader can validate the functionality of this 
template by performing the same steps as the previous exercise. 

**Deployment**

This stack can be created using the following command:

.. code:: bash

  openstack stack create -t ex4.4.yaml -e env.yaml ex4.4 --parameter user=my_user

ex4.5.yaml
----------

This template makes use of the concept of nested templates to instead of 
installing and configuring a webserver within the template, make use of a 
prebuilt webserver application template. 

**Notes** 

Thus far the webserver instance has been built in much the same way in every 
template thus indicating that we can create an application template that can 
easily be referenced and thus minimizing the amount of code in our main 
template. The reader will notice that the *instance* resource definition is now 
of type Tutorial::Application::HTTP::NoWait (more on NoWait vs. Wait later) and 
investigating the environment file the reader will find the following entry 
under *resource_registry*:

.. code:: yaml

  Tutorial::Application::HTTP::NoWait: lib/applications/httpd_no_wait.yaml

Opening that file, the reader will notice a similar format to our previous 
exercises, the only difference being that the software configuration is a file 
path to *../softwareconfigs/httpd.yaml*. By going further down the rabbit hole, 
the reader will notice that the webserver software configuration has been 
broken down into three parts, namely: http_install, http_configure, and 
http_start all strung together via an OS::Heat::MultipartMime resource 
definition. This template has the resulting OS::Heat::MultipartMime config as 
an output. Another interesting point to notice within the softwareconfig 
template is that each part references the configuration via the *get_file* 
intrinsic function. This exercise shows the true power and flexibility of using 
a nested structure to build a full application deployment.  

**Deployment**

The stack can be create using the following command:

.. code:: bash

  openstack stack create -t ex4.5.yaml -e env.yaml ex4.5

**Extras**

Within the configuration section of the webserver application template, a 
*message* is passed which fills the contents of /var/www/html/index.html and 
will be served when curl-ing the server. For a more realistic webserver, a git 
url should be passed and the configuration script should perform a *git clone 
<git url>* within the /var/www/html directory. This way actual webserver 
content can be easily deployed either in a dev or prod environment.  


ex4.6.yaml
----------

This template aims to illustrate the main problem with creating dependencies 
between resources while using cloud-init

**Notes**

This template builds upon the previous exercise and an additional instance is 
created and assigned a floating IP. The user_data for this extra instance looks 
as follows:

.. code:: yaml 

  ..
  user_data:
    str_replace:
      params:
        $ip: { get_attr: [ http_floating_ip, floating_ip_address ] }
      template: |
        #!/bin/bash
        echo "Data gathered from http: `curl $ip`" > /tmp/hello
  ..

Basically this script performs a curl on the floating IP assigned to the *http* 
resource. It gathers this IP address by using the *get_attr* function and thus 
a dependency is created between the *instance* resource and the *http* 
resource. This means that the *instance* resource will be not created until the 
*http* resource reaches the state CREATE_COMPLETE. Ideally, the /tmp/hello file 
on the *instance* will contain "Data gathered from http: Webservers are 
awesome!". The "Webservers are awesome!" is the message the *http* resource was 
initialized with.

Upon the successful deployment of this template the user can check the contents 
of /tmp/hello file as follows:

.. code:: bash

  $ ssh -i ../key-pairs/heat_key centos@<instnce_floating_ip> "cat /tmp/hello"

Unless there was some very bad timing (I probably should have added a sleep in 
the configure script for the webserver), this command will return: 

.. code:: text 

  Data gathered from http:

This happens due to the fact that as soon as the *http* instance is spawned, it 
is marked as *CREATE_COMPLETE* when in fact the instance should have been in 
the state *CREATE_IN_PROGRESS* until the httpd service was successfully started 
and thus cloud-init finished running the scripts provided in user_data. The 
next exercise addresses this issue. 

For extra validation of this behaviour, the reader is encouraged to curl the 
floating IP of the *http* resource and see that the webserver did indeed finish 
configuring and returns "Webservers are awesome!" 

**Deployment**

The stack can be create using the following command:

.. code:: bash

  openstack stack create -t ex4.6.yaml -e env.yaml ex4.6


ex4.7.yaml
----------

This template introduces the `OS::Heat:WaitCondition 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::WaitCondition>`_ 
and the `OS::Heat::WaitConditionHandle 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::WaitConditionHandle>`_ 
resources and how they can be used to mark the instance state as 
*CREATE_COMPLETE* only after cloud-init finishes running the scripts provided 
in user_data

**Notes**

The only difference between the ex4.6.yaml and ex4.7.yaml template is that the 
*http* resource is now of type *Tutorial::Application::HTTP::Wait* as opposed 
to *Tutorial::Application::HTTP::NoWait*. Investigating the env.yaml file, the 
corresponding file for *Tutorial::Application::HTTP::Wait* is 
*lib/applications/httpd_wait.yaml*. Within this file there are a number of new 
resource definitions:

.. code:: yaml

  ..
  wait_condition:
    type: OS::Heat::WaitCondition
    properties:
      handle: { get_resource: wait_handle }
      count: 1
      timeout: 600

  wait_handle:
    type: OS::Heat::WaitConditionHandle

  http_signal:
    type: OS::Heat::SoftwareConfig
    properties:
      group: ungrouped
      config:
        str_replace:
          params:
            wc_notify: { get_attr: [wait_handle, curl_cli] }
          template: |
            #!/bin/bash
            wc_notify --data-binary '{"status": "SUCCESS"}'
  ..

The *wait_handle* is a resource of type `OS::Heat::WaitConditionHandle 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::WaitConditionHandle>`_ 
and the *wait_condition* is a resource of type `OS::Heat:WaitCondition 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::WaitCondition>`_ 
which has a property named handle that links to the *wait_handle* resource. The 
OS::Heat::WaitCondition resource instantiates a special resource that can be 
signaled from an instance through a handle. This resource will change its 
state only after it receives the number of signals specified in the count 
property. A timeout property specifies the time it will wait for those signals. 

Basically any resource (such as an instance) that is associated with a 
WaitConditionHandle will remain in the *CREATE_IN_PROGRESS* state until the 
WaitCondition resource that is associated with that particular 
WaitConditionHandle (in this case *wait_handle*) will recevie a signal 
indicating a SUCCESS status. 

The *http_singnal* resource is a SoftwareConfig resource that does exactly 
that. It uses the *get_attr* intrinsic function to get the appropriate curl 
command to send the apporiate signal to the *wait_condition* resource (as well 
as create the previously mentioned dependency between the SoftwareConfig 
resource and the WaitConditionHandle resource). The 
OS::Heat::WaitConditionHandel has various `signal transports 
<http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::WaitConditionHandle-prop-signal_transport>`_ 
that it can utilize. This template uses the TOKEN_SIGNAL (default value) 
transport which will perform a HTTP POST to a Heat API endpoint with the 
provided keystone token (where the curl command comes from). 

Lastly, the *http_signal* SoftwareConfig resource must be associated with the 
instance that should send the signal. This is done via:

.. code:: yaml

  http:
    type: ../softwareconfigs/httpd.yaml
    properties:
      msg: { get_param: msg }

  http_config:
    type: OS::Heat::MultipartMime
    properties:
      parts:
        - config: { get_attr: [http, config] }
          type: multipart
        - config: { get_resource: http_signal }

In the *http_no_wait.yaml* template the *http* resource was the only 
SoftwareConfig resource the *instance* (webserver resource) was associated 
with. Here, a MultipartMime resource was used in order to combine the 
configuration for the webserver and the signal. Do note that the order in which 
they are combined in the MultipartMime matters as the webserver must be 
configured first and the signal indicating SUCCESS should be sent after. The 
*instance* user_data now uses the *get_resource* intrinsic function to link the 
user_data attribute to the *http_config* MultipartMime like so:

.. code:: yaml

  ..
  user_data: { get_resource: http_config }
  ..

Upon the successful deployment of this template the user can check the contents 
of /tmp/hello file on the *instance* resource defined in the main template as 
follows:

.. code:: bash

  $ ssh -i ../key-pairs/heat_key centos@<instnce_floating_ip> "cat /tmp/hello"

And the resulting output should be:

.. code:: text

  Data gathered from http: Webservers are awesome!

**Deployment**

The stack can be create using the following command:

.. code:: bash

  $ openstack stack create -t ex4.7.yaml -e env.yaml ex4.7

ex4.8.yaml
----------

This template aims to illustrate the effects of updating a stack with a 
modification to the *user_data* attribute of an instance

**Notes**

The only difference between this template and one in the previous exercise is a 
simple echo command was added to the user_data script of the *instance* 
resource definition, like so:

.. code:: yaml

  ..
  user_data:
    str_replace:
      params:
        $ip: { get_attr: [ http_floating_ip, floating_ip_address ] }
      template: |
        #!/bin/bash
        echo "Data gathered from http: `curl $ip`" > /tmp/hello
        echo "Tiny modification to user_data script"
  ..

Even though this modification only echos to the console of the instance, 
performing a *stack update* command on the previous stack will result in that 
instance being completely destroyed and redeployed from scratch. The purpose of 
this exercise is to introduce the next part of this tutorial that uses a 
different software orchestration engine that allows for software configuration 
updates without replacement. 

After performing the stack update command, the reader is encouraged to monitor 
the status of the instances using the following command:

.. code:: bash

  $ watch nova list 

Alternatively, the user can also login to the instance and verify its uptime. 

**Deployment**

The stack can be updated using the following command:

.. code:: bash

  $ openstack stack update -t ex4.8 -e env.yaml ex.4.7
