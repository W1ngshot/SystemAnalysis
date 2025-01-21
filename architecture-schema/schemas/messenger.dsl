workspace {

    model {
        user = person "User"
        softwareSystem = softwareSystem "Software System" {
            webApp = container "Web Application" {
                user -> this "Uses"
            }
            
            mobileApp = container "Mobile Application" {
                user -> this "Uses"
            }
            
            gateway = container "Gateway" {
                webApp -> this "Requests"
                mobileApp -> this "Requests"
            }
            
            keycloak = container "Keycloak" "External Identity Service" {
                gateway -> this "Register/Get token"
                this -> gateway "Token"
            }

            mainApi = container "Main API Application" "Provides actions with API via Json" "ASP .NET" {
                userEndpoints = component "User Endpoints" "Endpoints for user profiles" "ASP .NET" {
                    gateway -> this "Calls"
                }
                userModule = component "User Module" "Actions with user profiles" "ASP .NET" {
                    userEndpoints -> this "Calls"
                }
                
                fileEndpoints = component "File Endpoints" "Endpoints for actions with files" "ASP .NET" {
                    gateway -> this "Calls"
                }
                fileModule = component "File Module" "Actions with files" "ASP .NET" {
                    fileEndpoints -> this "Calls"
                }

                convEndpoints = component "Conversation Endpoints" "Endpoints for basic conversations actions" "ASP .NET" {
                    gateway -> this "Calls"
                }

                channelEndpoints = component "Channel Endpoints" "Endpoints for channels" "ASP .NET" {
                    gateway -> this "Calls"
                }
                channelModule = component "Channel Module" "Actions with channels" "ASP .NET" {
                    channelEndpoints -> this "Calls"
                    convEndpoints -> this "Calls"
                }

                groupEndpoints = component "Group Endpoints" "Endpoints for group chats" "ASP .NET" {
                    gateway -> this "Calls"
                }
                groupModule = component "Group Module" "Actions with group chats" "ASP .NET" {
                    groupEndpoints -> this "Calls"
                    convEndpoints -> this "Calls"
                }

                pmEndpoints = component "Private Message Endpoints" "Endpoints for private messages" "ASP .NET" {
                    gateway -> this "Calls"
                }
                pmModule = component "Private Message Module" "Actions with private messages" "ASP .NET" {
                    pmEndpoints -> this "Calls"
                    convEndpoints -> this "Calls"
                }

                outboxProcessModule = component "Outbox Pattern Process Module" "Processing Messages From Postgres To Kafka" "ASP .NET" {
                }
            }

            container "Redis Storage" {
                userModule -> this "Reads from and writes to"
                pmModule -> this "Reads from and writes to"
                channelModule -> this "Reads from and writes to"
                groupModule -> this "Reads from and writes to"
                fileModule -> this "Reads from and writes to"
            }

            container "Postgres Database" {
                userModule -> this "Reads from and writes to"
                pmModule -> this "Reads from and writes to"
                channelModule -> this "Reads from and writes to"
                groupModule -> this "Reads from and writes to"
                fileModule -> this "Reads from and writes to"
                outboxProcessModule -> this "Reads from and writes to"
            }

            container "Minio Storage" {
                fileModule -> this "Reads from and writes to"
                gateway -> this "Gets files via presigned urls"
            }

            kafka = container "Kafka" {
                outboxProcessModule -> this "Produce"
            }

            notifications = container "Notifications Microservice" "Realtime communication for notification messages" "ASP .NET" {
                notificationConsumer = component "Notification consumer" "Consumer for notifications messages" "ASP .NET" {
                    kafka -> this "Consume"
                }
                notificationModule = component "Notification Module" "Provides websocket connections" "ASP .NET" {
                    notificationConsumer -> this "Calls"
                    this -> gateway "Notifications via websockets if user online"
                    gateway -> this "Connects via websockets"
                }
            }
            
            container "Notification Redis Storage" {
                notificationModule -> this "Reads from and writes to"
            }
            
            container "Push Notification Service" {
                notificationModule -> this "Calls if user is not connected to websockets"
                this -> gateway "Notifications via push if user not online"
            }
            
            
        }
    }

    views {
        systemContext softwareSystem {
            include *
            autolayout lr
        }
        
        container softwareSystem {
            include *
            autolayout lr
        }
        
        component mainApi {
            include *
            autolayout lr
        }

        component notifications {
            include *
            autolayout lr
        }

        theme default
    }

}