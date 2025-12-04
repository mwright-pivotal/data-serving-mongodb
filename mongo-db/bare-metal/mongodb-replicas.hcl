# /home/mwright/projects/server/mongodb-job.hcl
# Nomad job to run a 2-node MongoDB replica set using the exec2 driver.
# Note: this job starts two mongod processes with --replSet=rs0 and stores data
# under the allocation directory. After both allocations are running you must
# initialize the replica set manually (example below).
#
# Example one-time init (run from a machine with mongo shell or inside one alloc):
#   mongo --host <ip1>:27017 --eval 'rs.initiate({_id:"rs0", members:[{_id:0, host:"<ip1>:27017"},{_id:1, host:"<ip2>:27017"}]})'
#
# Replace <ip1> and <ip2> with the allocation IPs (or use Consul/Service discovery).
# This job does not attempt automatic bootstrap to keep the Nomad job simple and
# predictable for bare-metal installs.

job "mongodb" {
    datacenters = ["dc1"]
    type = "service"
  
    constraint {
      attribute = "${node.class}"
      value     = "CPU_only"
    }

    group "mongodb-replicaset" {
        # Run two MongoDB server allocations
        # count = 2

        # Ask Nomad to spread allocations across distinct hosts when possible
        spread {
            attribute = "${node.unique.hostname}"
        }

        network {
            # Expose MongoDB port; Nomad will allocate a host port and set NOMAD_PORT_db
            port "db1" {
                static = 27017
            }
          	port "db2" {
               static = 27027
            }
        }
        task "create-mongodb-folders" {
          user = "admin"
          lifecycle {
            hook = "prestart"
            sidecar = false
          }

          driver = "exec"
          config {
            command = "/bin/sh"
            args = ["-c", "mkdir -p \"$NOMAD_ALLOC_DIR/mongo/data1\" \"$NOMAD_ALLOC_DIR/mongo/data2\" \"$NOMAD_ALLOC_DIR/mongo/log\""]
          }
        }
        task "mongod-replica1" {
            driver = "exec2"
            user = "admin"

            # Run a shell that prepares per-allocation data dirs and execs mongod in foreground.
            # Uses NOMAD_ALLOC_DIR, NOMAD_TASK_DIR and NOMAD_PORT_db injected at runtime by Nomad.

            # Download the MongoDB binary tarball into the task directory. Nomad will
            # automatically extract the .tgz into the task directory (the tarball
            # expands to a folder named `mongodb-linux-x86_64-rhel93-8.2.2`).
            artifact {
                source = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel93-8.2.2.tgz"
            }

            config {
                command = "/bin/sh"
                args = [
                    "-c",
                    "set -euo pipefail; exec \"$NOMAD_TASK_DIR/mongodb-linux-x86_64-rhel93-8.2.2/bin/mongod\" --replSet rs0 --bind_ip_all --dbpath \"$NOMAD_ALLOC_DIR/mongo/data1\" --port ${NOMAD_PORT_db1} --logpath \"$NOMAD_ALLOC_DIR/mongo/log/mongod-rs1.log\""
                ]
            }

            env {
                REPLICA_SET = "rs0"
            }

            resources {
                cpu    = 500      # 500 MHz
                memory = 1024      # MB
            }

            service {
                provider = "nomad"
                name = "mongo-replica1"
                port = "db1"
                tags = ["mongodb", "replica"]

                # Simple TCP health check
                check {
                    name     = "tcp"
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }

            restart {
                attempts = 10
                interval = "5m"
                delay    = "15s"
                mode     = "delay"
            }
        }
        task "mongod-replica2" {
            driver = "exec2"
						user = "admin"
            # Run a shell that prepares per-allocation data dirs and execs mongod in foreground.
            # Uses NOMAD_ALLOC_DIR, NOMAD_TASK_DIR and NOMAD_PORT_db injected at runtime by Nomad.

            # Download the MongoDB binary tarball into the task directory. Nomad will
            # automatically extract the .tgz into the task directory (the tarball
            # expands to a folder named `mongodb-linux-x86_64-rhel93-8.2.2`).
            artifact {
                source = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel93-8.2.2.tgz"
            }

            config {
                command = "/bin/sh"
                args = [
                    "-c",
                    "set -euo pipefail; exec \"$NOMAD_TASK_DIR/mongodb-linux-x86_64-rhel93-8.2.2/bin/mongod\" --replSet rs0 --bind_ip_all --dbpath \"$NOMAD_ALLOC_DIR/mongo/data2\" --port ${NOMAD_PORT_db2} --logpath \"$NOMAD_ALLOC_DIR/mongo/log/mongod-rs3.log\""
                ]
            }

            env {
                REPLICA_SET = "rs0"
            }

            resources {
                cpu    = 500      # 500 MHz
                memory = 1024      # MB
            }

            service {
                provider = "nomad"
                name = "mongo-replica2"
                port = "db2"
                tags = ["mongodb", "replica"]

                # Simple TCP health check
                check {
                    name     = "tcp"
                    type     = "tcp"
                    interval = "10s"
                    timeout  = "2s"
                }
            }

            restart {
                attempts = 10
                interval = "5m"
                delay    = "15s"
                mode     = "delay"
            }
        }
    }
}
