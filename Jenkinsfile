pipeline {
    environment {
        ANSIBLE_INVENTORY = 'hosts'
        ANSIBLE_PLAYBOOK = 'web_deploy.yml'
        ANSIBLE_USER = "${ANSIBLE_USERS}"
        ANSIBLE_PASSWORD = "${ANSIBLE_PASS}"
        VM_ADDRESS = '192.168.31.8'
        APP_CONTAINER_PORT = "5000"
        APP_EXPOSED_PORT = "80"
        DOCKERHUB_ID = "tooll124"
        DOCKERHUB_PASSWORD = credentials('dockerhub_password')
    }

    agent any

    stages {
        stage('Build image') {
            when {
                expression { BRANCH_NAME == 'master/origin' }
            }
            steps {
                script {
                    sh "docker build -t ${DOCKERHUB_ID}/IMAGE_NAME:IMAGE_TAG ."
                }
            }
        }

        stage('Run container based on built image') {
            when {
                expression { BRANCH_NAME == 'master/origin' }
            }
            steps {
                script {
                    sh """
                        echo "Cleaning existing container if it exists"
                        docker ps -a | grep -i IMAGE_NAME && docker rm -f IMAGE_NAME
                        docker run --name IMAGE_NAME -d -p ${APP_EXPOSED_PORT}:${APP_CONTAINER_PORT} ${DOCKERHUB_ID}/IMAGE_NAME:IMAGE_TAG
                        sleep 5
                    """
                }
            }
        }

        stage('Test image') {
            steps {
                script {
                    sh """
                        curl -v 172.17.0.1:${APP_EXPOSED_PORT} | grep -i "Dimension"
                    """
                }
            }
        }

        stage('Clean container') {
            steps {
                script {
                    sh """
                        docker stop IMAGE_NAME
                        docker rm IMAGE_NAME
                    """
                }
            }
        }

        stage('Login and Push Image to Docker Hub') {
            steps {
                script {
                    sh """
                        echo ${DOCKERHUB_PASSWORD} | docker login -u ${DOCKERHUB_ID} --password-stdin
                        docker push ${DOCKERHUB_ID}/IMAGE_NAME:IMAGE_TAG
                    """
                }
            }
        }

        stage('Test application has been deployed correctly') {
            agent {
                docker {
                    image 'registry.gitlab.com/robconnolly/docker-ansible:latest'
                }
            }
            steps {
                script {
                    sh 'ansible-galaxy install -r roles/requirements.yml'
                    sh 'ansible all -m ping -i hosts --private-key id_rsa'
                }
            }
        }

        stage('Deploy with Ansible') {
            when {
                expression { BRANCH_NAME == 'master/origin' }
            }
            steps {
                script {
                    def ansibleInventory = """
                        [web]
                        ${VM_ADDRESS} ansible_user=${ANSIBLE_USER} ansible_ssh_pass=${ANSIBLE_PASSWORD}
                    """
                    writeFile file: ANSIBLE_INVENTORY, text: ansibleInventory

                    sh "cp ../ansible/${ANSIBLE_PLAYBOOK} ."

                    sh "ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOK}"
                }
            }
        }
    }
}
