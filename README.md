
Hello world – Devops CI/CD project

Tools:
    • VC - Git
    • SCM -  Github
    • Code base - Java
    • Build Tool - Maven 
    • CI – Jenkins
    • Deployment - Docker

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
