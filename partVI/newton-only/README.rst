ex5.3.yaml
----------

This exercise showcases how a SoftwareConfiguration can be applied to a ResourceGroup via the use of SoftwareDeploymentGroup resource

**Notes**
                                                                                                                                                                             The reader will notice a new type of resource namely, `OS::Heat::SoftwareDeploymentGroup <http://docs.openstack.org/developer/heat/template_guide/openstack.html#OS::Heat::SoftwareDeploymentGroup>`_. This resource behaves exactly the same as a *OS::Heat::SoftwareDeployment* resource except for that the *server* attribute becomes *servers* attribute which will associate a map of instances names and instance uuids with this SoftwareDeployment instead of only one. This map can be retrieved via the *refs_map* attribute
                                                                                                                                                                              of the *ResourceGroup* resource.

                                                                                                                                                                              The reader should create the stack, and then update it (as the SoftwareDeploymentGroup only acts upon the UPDATE action) with a new message and validate the update operation by curling each server for the new message.

                                                                                                                                                                              **Deployment**

                                                                                                                                                                              This stack can be created as follows:

                                                                                                                                                                              .. code:: bash

                                                                                                                                                                                $ os stack create -t ex6.3.yaml -e env.yaml ex6.3 --parameter cluster_size=2

                                                                                                                                                                                and updated as follows:

                                                                                                                                                                                .. code:: bash



