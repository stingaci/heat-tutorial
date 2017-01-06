Openstack Orchestration Tutorial
================================

This tutorial aims to illustrate the concepts surrounding orchestration in 
Openstack both infrastructure orchestration and software configuration 
orchestration. The first three part of the tutorial focus on orchestrating 
Opnestack infrastrucuture resources while the latter part of the tutorial 
focuses on orchestrating software configurations via the use of cloud-init and 
Heat software deployments. 

`Part I - Heat Basics <https://github.com/stingaci/heat-tutorial/tree/master/partI>`_
  Basic single-vm HOT templates (resources, parameters, outputs, intrinsic 
  functions)

`Part II - Full Stack Deployment <https://github.com/stingaci/heat-tutorial/tree/master/partII>`_
  Full-stack deployment for single-vm (vm, networks, floating-ip, 
  security-groups)

`Part III - Multi-instance deployments <https://github.com/stingaci/heat-tutorial/tree/master/partIII>`_
  Nested templates, heat environments

`Part IV -Cloud-Init & Heat <https://github.com/stingaci/heat-tutorial/tree/master/partIV>`_
  User data scripts, cloud-config, application deployment/configuration 
  examples, signaling
 
`Part V - Software Deployments <https://github.com/stingaci/heat-tutorial/tree/master/partV>`_
  Software configuration alternative to cloud-init, VM lifecycle managment, 
  non-replacement software configuration updates 

`Part VI - Vertical and Horizontal Scaling <https://github.com/stingaci/heat-tutorial/tree/master/partVI>`_
  Scaling a stack vertically (increase instance resources) or horizontally 
  (add more instances; loadbalancers)

Format
======

Each part in this tutorial has it's own directory with a README.rst which the 
reader should follow while performing each exercise. Each README is quite 
extensive and contains useful links as well as documentation on each exercise. 

Prerequsites & Other Details
============================

This tutorial was built for the Openstack Liberty release however most concepts 
are applicable even up to the Newton release. I am planning on updating this 
tutorial to a newever version in the near feature. This tutorial also assumed 
you are working with a RHEL based image (a Centos 7 image is used all 
throughout the exercises). This second point only becomes more important in 
the second half of the tutorial when software configurations are thought. 

Lastly, this tutorial assumes that you created a keypair in the key-pairs 
folder of the tutorial named *heat_key*. The reader can create this key as 
follows:

.. code:: bash 

  $ openstack keypair create heat_key > key-pairs/heat_key

Links & Credits 
===============

The format of this tutorial as well as some of the exercises have been inspired 
by `Miguel Grinberg's 4-part tutorial 
<https://developer.rackspace.com/blog/openstack-orchestration-in-depth-part-1-introduction-to-heat/>`_. 
I'd also like to thank Steve Hardy and his `Software Deployment Primer 
<http://hardysteven.blogspot.com/2015/05/heat-softwareconfig-resources.html?m=1>`_. 
Lastly, I'd like to thank the Heat community for all their help on the #heat 
channel, their contintous support and quick replies.

Here's a list of usefull links, that the reader could definitely benefit from:

Openstack Docs
--------------

- `Heat Template Guide <http://docs.openstack.org/developer/heat/template_guide/>`_
- `Heat Template Specification <http://docs.openstack.org/developer/heat/template_guide/hot_spec.html>`_
- `Heat Resource Types and Details Specifications <http://docs.openstack.org/developer/heat/template_guide/openstack.html>`_ 
- `Heat Software Configruation <http://docs.openstack.org/developer/heat/template_guide/software_deployment.html#software-deployment-resources>`_
- `Heat API Specification <http://developer.openstack.org/api-ref/orchestration/v1/>`_
- `Heat Authorization Model <http://docs.openstack.org/admin-guide/orchestration-auth-model.html>`_
- `Heat Stack Domain (Purpose & Configuration) <http://docs.openstack.org/admin-guide/orchestration-stack-domain-users.html>`_

Other Heat Tutorials
--------------------

- `Miguel Grinberg's OpenStack Orchestration In Depth Tutorial <https://developer.rackspace.com/blog/openstack-orchestration-in-depth-part-1-introduction-to-heat/>`_
- `Pablo Nelson's Spining Up Stacks Using Heat Tutorial <https://github.com/rackerlabs/heat-tutorial>`_

Software Deployments
--------------------

- `Software Deployment Primer <http://hardysteven.blogspot.com/2015/05/heat-softwareconfig-resources.html?m=1>`_
- `Generic Software Configs <https://developer.rackspace.com/docs/user-guides/orchestration/generic-software-config/>`_
- `Software Config gitHub repo <https://github.com/openstack/heat-templates/tree/master/hot/software-config>`_
- `OpenStack Heat And os-collect-config <https://fatmin.com/2016/02/23/openstack-heat-and-os-collect-config/>`_

Cloud-init
---------

- `Cloud-init Docs <http://cloudinit.readthedocs.io/en/latest/>`_
- `Cloud-config Examples <http://cloudinit.readthedocs.io/en/latest/topics/examples.html>`_
- `Using cloud-init With Heat <https://sdake.io/2013/03/03/how-we-use-cloudinit-in-openstack-heat/>`_

