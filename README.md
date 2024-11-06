
Hello world – Devops CI/CD project

Tools:
    • VC - Git
    • SCM -  Github
    • Code base – Java
    • CI – Jenkins
    • Build Tool - Maven 
    • SCA – Sonarqube
    • SAST – OWASP
    • Jfrog - Artifactory
    • Deployment – Docker

Upload the code from local to remote (git to github):

Copy the source from the developer <Helloworld-uk>
cd <project>
git init
git add .
git status
git config --global user.email itsthebhuvanesh9998@gmail.com
git config --global user.name bhuvanesh1998-oss
git commit -m ‘<msg>’

https://github.com/bhuvanesh1998-oss/Devops-Helloworld.git

create a new repository on the command line:
echo "# Devops-Helloworld" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/bhuvanesh1998-oss/Devops-Helloworld.git
git push -u origin main


Push an existing repository from the command line:
git remote add origin https://github.com/bhuvanesh1998-oss/Devops-Helloworld.git
git branch -M master
git push -u origin master

In Jenkins server:
    • Create the pipeline job in jenkins.
    • Configure your pipeline.
    • Install the plugins like maven integration, tool mvn3 (3.9.9), docker pipeline.
    • Install the docker pipeline plugin.
    • Install Publish over SSH

For the deployment process , we need the ssh connection between the CI server and deployment server.

jenkins ALL=(ALL) NOPASSWD: ALL  // in /etc/sudoers next to root

Generate the ssh key in jenkins server:
su – jenkins
ssh-keygen -t rsa -b 4096

Create one user and set nopasswd in deploymeny server:
adduser <user-name>
<user-name> ALL=(ALL) NOPASSWD: ALL 
su - <user-name>
mkdir -p ~/.ssh
Copy the id_rsa.pub by jenkins user in the CI-server (/var/lib/jenkins/.ssh) and paste it in the deployment server:
echo <id_rsa.pub> >> ~/.ssh/authorized_keys

Try to take SSH from the  CI server:
ssh <user-name>@privateIP // It doesnot prompted for password


Dashboard -> Manage Jenkins -> System -> SSH servers -> 

    • Name the server.
    • Add the private IP of the deployment server in hostname.
    • Add the username <user-name>.
    • Advanved, use password authentication add the password of the <user-name>.
    • Apply and save.

// If error comes paste the private ssh keys (id_rsa) from thr CI server by the jenkins user in key field.

Dashboard -> job -> Pipeline syantax -> snippet generator -> ssh publisher: send build artifacts over ssh -> Exec command -> (The command which we have to execute) -> Generate pipeline script.

// By using this script just update the deployment stages.

Chmod 777 /var/run/docker.sock // in deployment server.

Pipeline:

pipeline {
    environment {
        imagename = "bhuvaneshnexn/devops-helloworld"
        registryCredential = 'docker-bhuvanesh'
        dockerImage = ''
    }
    
    agent any
    
    tools { 
        maven 'mvn3' 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']], 
                    extensions: [], 
                    userRemoteConfigs: [[url: 'https://github.com/bhuvanesh1998-oss/Devops-Helloworld.git']]
                )
                
                echo 'Checkout Completed'
            }
        }
        
     
        stage('Maven Build') {
            steps {
                sh 'mvn clean install'
            }
        }
        
        
     
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build(imagename)
                }
            }
        }
        

        
        stage('Deploy Docker Image') {
            steps {
                script {
                    docker.withRegistry('', registryCredential) {
                        dockerImage.push("$BUILD_NUMBER")
                        dockerImage.push('latest')
                    }
                }
            }
        }
        stage('Pull Docker Image') {
            steps {
                    sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker pull bhuvaneshnexn/devops-helloworld', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
                }
            }
        
        stage('Run Docker Image') {
            steps {
                    sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker run -itd --name=hollo-world-devops -p 8083:8083 bhuvaneshnexn/devops-helloworld', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
                }
            }
        
          
    }
}


**Implementing Devsecops:**

Installed tools and Plugins:
    • sonar scanner – tool 4.6.02311
    • OWASP dependency check – tool 6.5.0

Sonarqube:        (admin/admin)

Install in CI server or an individual machine:
docker container run -itd p 9000:9000 –name sonarserver sonarqube:8.2community

Install sonarqubescanner plugin:

Dashboard -> Manage jenkins -> Plugin -> sonarqube scanner .
Manage Jenkins -> Global tools configuration -> sonarqube scanner -> sonar-scanner -> Install automatically -> 4.6.02311 -> Apply and save.

Login in sonarqube.

Create new project -> Project name -> Setup ->(Project name) Generate token -> continue -> select the language as java -> Build tool Maven -> copy and paste it in the pipeline.

mvn sonar:sonar \
  -Dsonar.projectKey=devsecops-java \
  -Dsonar.host.url=http://172.18.11.182:9000 \
  -Dsonar.login=90698c8dfaeff17aace722dcc27b064b79c5996c

OWASP:

Install OWASP pligin named as OWASP dependency check
Install tool -> Dependency check installations -> add dependency check -> Name (Dp-check) -> Install automatically -> Install from github.com -> depenndency check 6.5.0 -> apply and save

// Name should be mapped correctly in the pipeline.

Jfrog:     (admin/password)  -> Admin@123

https://jfrog.com/help/r/jfrog-installation-setup-documentation/install-artifactory-single-node-with-docker

Jfrog Installation:
mkdir -p $JFROG_HOME/artifactory/var/etc/
cd $JFROG_HOME/artifactory/var/etc/
touch ./system.yaml
chown -R 1030:1030 $JFROG_HOME/artifactory/var

sudo chmod -R 777 $JFROG_HOME/artifactory/var

sudo nano system.yaml 
shared:
  database:
    driver: org.postgresql.Driver
    type: postgresql
    url: jdbc:postgresql://<docker0_IP>:5432/artifactorydb  
    username: artifactory
    password: password


Running Postgress:
sudo docker run --name postgres -itd -e POSTGRES_USER=artifactory -e POSTGRES_PASSWORD=password -e POSTGRES_DB=artifactorydb -p 5432:5432 library/postgres

Running Jfrog:
sudo docker run --name artifactory -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss

check the artifactory logs with -f // error like masterkey missing

ip addr show docker0

copy the docker0 address and paste in the system.yaml file
url: jdbc:postgresql://<docker0_IP>:5432/artifactorydb  //fetch ip by ip addr show docker0 in CI server or Jfrog server

Jfrog Token:

    • Login to the jfrog

    • create the repository -> select Maven -> Devsecops-java -> create local repository.

    • Profile -> Edit profile -> Type the admin password (Admin@123) -> unlock -> Generate identity token -> Next.

    • Copy the token and paste it in the pipeline next to API in jfrog stage.

    • Copt the path of the WAR or JAR or ER file and map there in the jfrog stage next to -t . 

    • Profile -> switch to classic UI -> Artifactory -> Artifacts -> (select the one u want) -> copy the file URL and paste in the jfrog stage followed by /$BHULD_NUMBER/<jarfile-name>.jar

<JFROG-token>

/var/lib/jenkins/workspace/Helloworld-devsecops/target/HelloWorld-uk-0.0.1-SNAPSHOT.jar

http://172.18.11.152:8082/artifactory/Devsecops-javaapp/$BUILD_NUMBER/HelloWorld-uk-0.0.1-SNAPSHOT.jar



Trivy:

https://aquasecurity.github.io/trivy/v0.18.3/installation/


sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy


Pipeline:

pipeline {
    environment {
        imagename = "bhuvaneshnexn/devops-helloworld"
        registryCredential = 'docker-bhuvanesh'
        dockerImage = ''
    }

    agent any

    tools { 
        maven 'mvn3' 
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/main']], 
                    extensions: [], 
                    userRemoteConfigs: [[url: 'https://github.com/bhuvanesh1998-oss/Devops-Helloworld.git']]
                )
                echo 'Checkout Completed'
            }
        }
        
        stage('Maven Build') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('Sonar Scan') {
            steps {
                sh """
                    export MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED"
                    mvn sonar:sonar \
                        -Dsonar.projectKey=devsecops-java \
                        -Dsonar.host.url=http://172.18.11.182:9000 \
                        -Dsonar.login=90698c8dfaeff17aace722dcc27b064b79c5996c
                """
            }
        }
     
        stage('JAR Scan with OWASP') {
            steps {
                dependencyCheck additionalArguments: '--format HTML', odcInstallation: 'Dp-check'
            }
        }
        
        stage('Push Artifact to JFrog') {
            steps {
                sh '''
                    curl -H "X-JFrog-Art-Api:<token>" \
                    -T /var/lib/jenkins/workspace/Helloworld-devsecops/target/HelloWorld-uk-0.0.1-SNAPSHOT.jar \
                    http://172.18.11.152:8082/artifactory/Devsecops-javaapp/$BUILD_NUMBER/HelloWorld-uk-0.0.1-SNAPSHOT.jar
                '''
            }
        }
     
        stage('Build Docker Image') {
            steps {
                script {
                    dockerImage = docker.build(imagename)
                }
            }
        }
        stage('Scan Docker Image by trivy') {
            steps {
                sh 'trivy image bhuvaneshnexn/devops-helloworld'
            }
        }
        stage('Push Docker Image to DockerHub') {
            steps {
                script {
                    docker.withRegistry('', registryCredential) {
                        dockerImage.push("$BUILD_NUMBER")
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Stop the running container') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker stop hollo-world-devops', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
        
        stage('Remove the stopped container') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker rm hollo-world-devops', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
        
        stage('Remove the Docker Image') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker rmi bhuvaneshnexn/devops-helloworld', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
        
        stage('Pull Docker Image') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker pull bhuvaneshnexn/devops-helloworld', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
        
        stage('Run Docker Image') {
            steps {
                sshPublisher(publishers: [sshPublisherDesc(configName: 'dev-server', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: 'docker run -itd --name=hollo-world-devops -p 8083:8083 bhuvaneshnexn/devops-helloworld', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '', remoteDirectorySDF: false, removePrefix: '', sourceFiles: '')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)])
            }
        }
    }
}

