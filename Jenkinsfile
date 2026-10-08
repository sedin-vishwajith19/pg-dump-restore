pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['DUMP', 'RESTORE'],
            description: 'Select action: DUMP (Backup DB & download artifact) or RESTORE (Restore DB onto server)'
        )

        file(
            name: 'DUMP_FILE_UPLOAD',
            description: '[RESTORE ACTION] Choose and upload a .dump file from your computer (Optional: leave empty if using RESTORE_DUMP_FILE)'
        )

        string(
            name: 'RESTORE_DUMP_FILE',
            defaultValue: '',
            description: '[RESTORE ACTION] Or specify existing dump filename/path (e.g. dumps/postgres_local_20261008_112000.dump)'
        )

        string(
            name: 'SSH_CREDENTIALS_ID',
            defaultValue: 'db-server-ssh-key',
            description: 'Jenkins Credential ID containing SSH Key for target database server'
        )

        string(
            name: 'SERVER_HOST',
            defaultValue: '98.70.45.119',
            description: 'Target DB Server IP address'
        )

        string(
            name: 'SERVER_USER',
            defaultValue: 'deployer',
            description: 'SSH user on target DB server'
        )

        string(
            name: 'CONTAINER_NAME',
            defaultValue: 'landmark-db',
            description: 'Docker container name running PostgreSQL'
        )

        string(
            name: 'DB_NAME',
            defaultValue: 'postgres_local',
            description: 'PostgreSQL database name'
        )

        string(
            name: 'DB_USER',
            defaultValue: 'postgres_local',
            description: 'PostgreSQL database user'
        )

        string(
            name: 'REMOTE_DUMPS_PATH',
            defaultValue: '/var/www/dkapp/DS_audit/dumps',
            description: 'Directory path on remote server for dump storage'
        )

        booleanParam(
            name: 'TAKE_SAFETY_SNAPSHOT',
            defaultValue: true,
            description: 'Take automatic safety snapshot before restoring'
        )
    }

    environment {
        LOCAL_DUMP_DIR = "${WORKSPACE}/dumps"
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '30'))
    }

    stages {
        stage('Initialize & Prepare') {
            steps {
                script {
                    echo "============================================================"
                    echo " Jenkins Database Self-Service Pipeline"
                    echo " Pipeline Action     : ${params.ACTION}"
                    echo " Target Server Host  : ${params.SERVER_USER}@${params.SERVER_HOST}"
                    echo " Target Container    : ${params.CONTAINER_NAME}"
                    echo " Target Database     : ${params.DB_NAME}"
                    echo "============================================================"

                    sh "chmod +x dump-db.sh restore-db.sh lib/*.sh"
                }
            }
        }

        stage('Execute Database Dump') {
            when {
                expression { return params.ACTION == 'DUMP' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        echo "Starting DB Dump operation..."
                        sh """
                            ./dump-db.sh \
                                --host "${params.SERVER_HOST}" \
                                --user "${params.SERVER_USER}" \
                                --container "${params.CONTAINER_NAME}" \
                                --dbname "${params.DB_NAME}" \
                                --dbuser "${params.DB_USER}" \
                                --dumps-path "${params.REMOTE_DUMPS_PATH}" \
                                --local-dir "${env.LOCAL_DUMP_DIR}"
                        """
                    }
                }
            }
            post {
                success {
                    script {
                        echo "Archiving dump files as Jenkins artifacts for developer download..."
                        archiveArtifacts artifacts: 'dumps/*.dump', allowEmptyArchive: false, fingerprint: true
                    }
                }
            }
        }

        stage('Execute Database Restore') {
            when {
                expression { return params.ACTION == 'RESTORE' }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: params.SSH_CREDENTIALS_ID, keyFileVariable: 'SSH_KEY_PATH')]) {
                    script {
                        def fileToRestore = ""

                        if (fileExists('DUMP_FILE_UPLOAD')) {
                            echo "Detected uploaded dump file from developer."
                            sh "mkdir -p dumps && mv DUMP_FILE_UPLOAD dumps/uploaded_restore.dump"
                            fileToRestore = "dumps/uploaded_restore.dump"
                        } else if (params.RESTORE_DUMP_FILE && params.RESTORE_DUMP_FILE.trim() != '') {
                            fileToRestore = params.RESTORE_DUMP_FILE.trim()
                        } else {
                            error("Please either upload a dump file (DUMP_FILE_UPLOAD) or specify RESTORE_DUMP_FILE parameter!")
                        }

                        echo "Starting DB Restore operation using file: ${fileToRestore}..."
                        def safetyFlag = params.TAKE_SAFETY_SNAPSHOT ? "" : "--no-safety"

                        sh """
                            ./restore-db.sh \
                                --host "${params.SERVER_HOST}" \
                                --user "${params.SERVER_USER}" \
                                --container "${params.CONTAINER_NAME}" \
                                --dbname "${params.DB_NAME}" \
                                --dbuser "${params.DB_USER}" \
                                --dumps-path "${params.REMOTE_DUMPS_PATH}" \
                                ${safetyFlag} \
                                "${fileToRestore}"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline run completed."
        }
        success {
            echo "Self-service database operation completed successfully!"
        }
        failure {
            echo "Operation failed. Please review execution log above."
        }
    }
}