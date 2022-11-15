# App Connect Enterprise 12.0.5.0-r2 with ITX 10.1 & UserExits on CP4I

## Overview
This repo showcases how to run a custom IBM ACE (App Connect Enterprise) container with ITX on OCP.  This documentation is designed to demonstrate how to lift & shift bar files for ACE flows running on-premises and seamlessly deploy them on OCP's Cloud Pak for Integration.  

Baking ITX into the ACE container optimizes runtime performance for ACE flows that leverage ITX while also avoiding any need to modify the original flow to function on OCP.

<img width="800" alt="ACEITXOCP" src="https://media.github.ibm.com/user/348652/files/62971d63-d7a6-4253-ac7c-a146c0b5a833">


This repo includes the following:

- A custom Docker file which combines IBM's supported ACE Container with ITX, its needed dependencies for ACE 12, and configuration for running User Exit
- A demo tutorial for running a basic ACE flow including a test ToUpperCase() ITX map on OCP
- Fully built out config maps for deploying ACE integration servers on CP4I without further customization required

*******************************************************************************************************************************************************************

## Environment

- IBM ROKS (VPC Gen2 with ODF) v4.10 [3 nodes x 16CPU/64GB]
- IBM Cloud Pak for Integration 6.0.4 Operator w/ Platform UI 2022.2.1 instance
- IBM App Connect 5.1.0 Operator w/ Quickstart Dashboard instance
- IBM MQ 2.1.0 Operator
- IBM Sterling Transformation Extender Runtime and Monitoring V10.1.1 Linux x86 Multilingual (Part number `M0519ML`)
- [OpenShift CLI](https://docs.openshift.com/container-platform/4.10/cli_reference/openshift_cli/getting-started-cli.html)

*All operators and instances were deployed to the `cp4i` namespace*  
*All terminal commands below are to be executed from the root of the repo*  

*******************************************************************************************************************************************************************

## Deployment Steps

### 1. Building `IntegrationServer` custom image  

#### Option 1 - Using the Build capability of OpenShift  

<br>

> If using this option make sure you have the proper credentials in place for github & ibm cloud pak image repository.  
> Update github-credentials in the yaml directory & create the secret  
> ``` 
> oc create -f yaml/github-credentials.yaml
> ```
> ![github_credentials](assets/github_credentials.png)
> 
> Create ibm-entitlement-key secret
>  ```
>  oc create secret docker-registry ibm-entitlement-key \ 
>    --docker-username=cp \ 
>    --docker-password=<entitlement_key> \
>    --docker-server=cp.icr.io \
>    --namespace=cp4i
>  ```
> ![entitlement_key_secret](assets/entitlement_key_secret.png) 

<br>

**a. Create ImageStream resource to store built images**  
  ```
  oc create -f yaml/ImageStream.yaml  
  ```
![image_stream](assets/image_stream.png)

<br>

**b. Create BuildConfig resource to build image**  
  Update ITX_URL in yaml/BuildConfig.yaml (make sure you get the bundle with the correct part number, see Environment section)
  ```
  oc create -f yaml/BuildConfig.yaml
  ```  
![build_config](assets/build_config.png)

<br>

**c. Build image**  
  ```
  oc start-build ace-itx-ue
  ```
![start_build](assets/start_build.png)

#### Option 2 - Building custom image locally

a. Download ITX 10.1 Runtime & Monitoring bundle & unpack to `itx` directory  
b. Open `itx/wmqi/dtxwmqi.sh` file & replace `%REPLACE_TXHOMEDIR%` with `/opt/ibm/itx`  
c. Build image with Podman/Docker using Dockerfile  
d. Upload image to a repository  

<br>

*******************************************************************************************************************************************************************

### 2. Configuring IBM MQ  

**a. Create a ConfigMap that contains the queue manager & queue parameters**  
  ```
  oc create -f yaml/ConfigMap.yaml
  ```  
![config_map](assets/config_map.png)

<br>

**b. Deploy Queue Manager instance**  
  ```
  oc create -f yaml/QueueManager.yaml
  ```  
![queue_manager](assets/queue_manager.png)

*******************************************************************************************************************************************************************

### 3. Storing ITX map in a `PersistentVolume`  

<br>

**a. Create `PersistentVolumeClaim` to reserve storage**  
  ```
  oc create -f yaml/PersistentVolumeClaim.yaml
  ```  
![persistent_volume_claim](assets/persistent_volume_claim.png)

<br>

**b. Deploy `Pod` to upload ITX map to `PersistentVolume`**  
  ```
  oc create -f yaml/Pod.yaml
  ```  
![pod](assets/pod.png)

<br>

**c. Copy ITX map to `PersistentVolume`**  
  ```
  oc cp test-files/Test.lnx itx-map-pv-loader:/maps
  ```  
![itx_map](assets/itx_map.png)

<br>

*******************************************************************************************************************************************************************

### 4. Instantiating the `IntegrationServer`  

The following steps are to be taken in the OpenShift Console GUI & CP4I GUI  

**a. Obtain Platform Navigator URL**  
Navigate to Operators -> Installed Operators -> IBM Cloud Pak for Integration -> Platform UI -> integration-quickstart 
![platform_url](assets/platform_url.png)

<br>

**b. Obtain admin credentials**  
Navigate to Workloads -> Secrets -> ibm-iam-bindinfo-platform-auth-idp-credentials
![platform_credentials](assets/platform_credentials.png)

<br>

**c. Login to CP4I PlatformNavigator and open the App Connect Dashboard (should be named `db-01-quickstart`)**  
![platform_login](assets/platform_login.png)

![ace_dashboard](assets/ace_dashboard.png)

<br>

**d. On the left bar pane select Configuration**  
![configuration](assets/configuration.png)  

<br>

**e. Create configuration**  
![create_configuration](assets/create_configuration.png)  

<br>

**f. Select type server.conf.yaml**  

**g. Import file from yaml directory**  

**h. Change name to `user-exit` & create**  

![completed_configuration](assets/completed_configuration.png)

<br>

**i. On the left bar pane select BAR files**  
![bar_file](assets/bar_files.png)

<br>

**j. Import External_ITX_Map.bar from test-files directory**  
![import_bar](assets/import_bar.png)  

<br>

**k. Click on breadcrumbs, select Display BAR URL & copy URL**  
![bar_url](assets/bar_url.png)

![copy_url](assets/copy_url.png)

<br>

**l. Update barURL in yaml/IntegrationServer.yaml (line 62)**  

![paste_url](assets/paste_url.png)

<br>

**m. Create `IntegrationServer`**  
  ```
  oc create -f yaml/IntegrationServer.yaml
  ```
![integration_server](assets/integration_server.png)

<br>

*******************************************************************************************************************************************************************

### 5. Testing  

**a. Start ITX flow**  
Select the `ace-itx-ue` Server Tile -> `ACE_ITX_Container_Test` Application Tile -> click breadcrumb for `ITX_FILE_Docker` and select `Setup` (*note: ignore error*) -> click breadcrumb for `ITX_FILE_Docker` and select `Start`
![start_itx_flow](assets/start_itx_flow.png)

<br>

**b. Log into terminal**  
In OCP, open Pod `ace-itx-ue-is-...` and select `Terminal` tab  

<br>

**c. Run test**  
  Change directory to `cd /home/aceuser/data/file_in` -> create test file `echo "test map" > test.txt` -> change directory to `cd /home/aceuser/data/file_out` -> confirm transformation is successful `cat ITX_output.txt`

![test_output](assets/test_output.png)
