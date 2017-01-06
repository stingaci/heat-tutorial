===============================
Part III - Nested Templates
===============================

In the previous section of this tutorial, the template size has increased 
drastically with the addition of the networking stack which creates template 
maintainability and readability issues. By the end of this part of the 
tutorial, the reader should be able to break down large templates into generic 
component templates, reference these components in a main template and lastly 
use environments to easily deploy templates or reference a particular working 
environment. 

Training Templates
==================

ex3.1.yaml
----------
  
This template serves as a main template and utilizes templates (or 
sub-components) defined in the lib/ directory to deploy an instance with a 
cinder volume attachment 

**Notes**

There are a number of important things to notice in template. First of all, a 
template can be referenced by specifying its path in the *type* attribute of 
the resource definition. The reader will also notice that each resource type 
that is a template has certain properties and these properties are not the same 
across all external templates. In fact properties of a resource that is a 
template directly map to the inputs you define within that template. 
Conversely, the outputs defined in a template become attributes of the resource 
defined within in the main template.

For example, the *network_stack* resource definition has two properties: 
public_network_id, and prefix. The template definition in 
lib/private_network.yaml, contains two parameters namely: public_network_id, 
and prefix. Conversely, this template contains an output called *name* which 
returns the name of the created private network. Within the main template, the 
*networks* attribute of the instance uses the *get_attr* function to return the 
attribute called *name* from the resource *network_stack*. 

The ability to effectively create new types of resources with their own 
properties and attributes allows for great flexibility and also allows for 
template sharing across multiple teams or departments in a easy manner. The 
most important point of developing sub-components as was done in this exercise 
is to create them as generic as possible. For example, in our previous 
exercises the CIDR for the subnet definition was hardcoded as opposed to the 
*private_network.yaml* definition where an input parameter was used.

**Deployment**

This template can be deployed as follows:

.. code:: bash

  os stack create -t ex3.1.yaml --parameter public_network_id=<public_network_id> --parameter application_name=full_stack ex3.1


ex3.2.yaml
---------------

This exercise introduces `Heat environments 
<http://docs.openstack.org/developer/heat/template_guide/environment.html>`_ 
and illustrates how they can be used to simplify template deployment as well as 
defining new resource type names. 

**Notes** 

This template is very similar to the previous, except for a very small 
difference. The previously referenced templates used the *type* attribute as a 
file path to the template. In this template, the type attribute looks something 
similar to Tutorial::NAME. If the reader attempts create a stack using this 
template, they will experience a resource type unknown error, as these types 
are not defined anywhere. 

Environments can be used to create new types. Inspecting the *env.yaml* file, 
the reader will notice this file contains two sections. The *resource_registry* 
section contains entries that define a list of names each with their own path, 
where the name becomes a resource type. The path can be a filepath, or URL as 
well. So for example, a department can have a git repository containing generic 
templates and the regular user can just create (or downloand an existing) 
environment file that points to the repo. 

Lastly, you'll notice there also is a parameters section, which allows the 
users to specify the command line parameters in this file instead. Thus, the 
user can now create a stack by only specifying two parameters, namely the 
template and the environment. Environments support a number of other features 
as well. The reader is encouraged to read the `Heat environments 
<http://docs.openstack.org/developer/heat/template_guide/environment.html>`_ 
documentation for more information.

**Deployment**

.. code-block:: bash

  openstack stack create -t ex3.2.yaml -e env.yaml ex3.2
