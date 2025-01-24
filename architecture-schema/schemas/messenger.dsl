workspace {

    model {
        user = person "Пользователь" "Конечный пользователь, взаимодействующий с системой"
        softwareSystem = softwareSystem "Программная система" "Основная система, предоставляющая услуги пользователям" {
            webApp = container "Web Application" "Фронтенд для пользователей на настольных компьютерах" {
                tags "web-app"
                
                user -> this "Взаимодействует через браузер"
            }
            
            mobileApp = container "Mobile Application" "Фронтенд для мобильных пользователей" {
                tags "mobile-app"
                
                user -> this "Взаимодействует через мобильное устройство"
            }
            
            proxy = container "Reverse Proxy" "Управляет и маршрутизирует входящие запросы к соответствующим сервисам" {
                tags "proxy"
                
                webApp -> this "Отправляет REST и WebSocket запросы"
                mobileApp -> this "Отправляет REST и WebSocket запросы"
            }
            
            keycloak = container "Keycloak" "Внешний сервис для аутентификации и авторизации" {
                tags "auth-service"
                
                proxy -> this "Обрабатывает регистрацию и вход пользователей"
            }

            messengerApi = container "Messenger Monolith Application" "Основное бэкенд приложение мессенджера" "ASP .NET" {
                tags "api"
            
                authHandler = component "Auth Hanlder" "Валидирует полученный токен при запросе, проверяя роли" "ASP .NET" {
                    this -> keycloak "Запрашивает метаданные авторизации"
                }
            
                api = component "API Layer (Minimal API Endpoints)" "Определяет эндпоинты для внешних запросов" "ASP .NET" {
                    proxy -> this "Перенаправляет REST-запросы"
                    this -> authHandler "Проверка авторизации при запросе защищенных эндпоинтов"
                }
                
                commandHandlers = component "Command Handlers" "Обрабатывают команды и обновляют состояние" "ASP .NET" {
                    api -> this "Выполняет команды через вызовы методов"
                }
                
                queryHandlers = component "Query Handlers" "Обрабатывают запросы и извлекают необходимые данные" "ASP .NET" {
                    api -> this "Выполняет запросы через вызовы методов"  
                }
                
                models = component "Models" "Модели предметной области, представляющие бизнес-сущности" "ASP .NET" {
                    commandHandlers -> this "Использует модели для обработки команд"
                    queryHandlers -> this "Использует модели для получения данных"
                }
                
                repositories = component "Repositories" "Управляют доступом к постоянному хранилищу данных" "ASP .NET" {
                    commandHandlers -> this "Обращается к хранилищу данных для выполнения команд"
                    queryHandlers -> this "Обращается к хранилищу данных для выполнения запросов"
                }
                
                externalServices = component "External Services" "Интегрируются с внешними API и системами" "ASP .NET" {
                    commandHandlers -> this "Взаимодействует с внешними системами"
                    queryHandlers -> this "Получает данные из внешних систем"
                }

                asyncProcessing = component "Outbox Pattern Process Module" "Обрабатывает несообщённые сообщения для Kafka" "ASP .NET" {
                    this -> repositories "Читает несообщённые сообщения из базы данных"
                }
            }

            container "Redis Cache" "Временное хранилище данных для быстрого доступа" {
                tags "cache"
                
                externalServices -> this "Читает и записывает данные в кэш"
            }

            container "Postgres Database" "Основная реляционная база данных для приложения" {
                tags "database"
                
                repositories -> this "Читает и записывает постоянные данные"
            }

            container "Minio Storage" "Система объектного хранилища для файлов и мультимедиа" {
                tags "storage"
                
                externalServices -> this "Сохраняет файлы и генерирует presigned URLs"
                proxy -> this "Предоставляет файлы через presigned URLs"
            }

            kafka = container "Kafka" "Брокер сообщений для асинхронной коммуникации" {
                tags "message-broker"
                
                asyncProcessing -> this "Публикует сообщения в топики"
            }

            notifications = container "Notifications Microservice" "Управляет уведомлениями в реальном времени для пользователей" "ASP .NET" {
                tags "microservice"
                
                notificationAuthHandler = component "Auth Hanlder" "Валидирует полученный токен при запросе, проверяя роли" "ASP .NET" {
                    this -> keycloak "Запрашивает метаданные авторизации"
                }
                
                consumers = component "Consumers" "Обрабатывают сообщения из Kafka для уведомлений" "ASP .NET" {
                    kafka -> this "Подписывается на топики и обрабатывает сообщения"
                }
                
                messageHandlers = component "Message Handlers" "Обрабатывают входящие сообщения и запускают соответствующие действия" "ASP .NET" {
                    consumers -> this "Вызывает методы для обработки уведомлений"
                }
                
                hubs = component "SignalR Hubs" "Управляет WebSocket-соединениями и уведомлениями" "ASP .NET" {
                    messageHandlers -> this "Получает обработанные уведомления для доставки"
                    this -> proxy "Отправляет уведомления через WebSocket, если пользователь онлайн"
                    proxy -> this "Устанавливает WebSocket-соединения"
                    this -> notificationAuthHandler "Проверка авторизации при подключении к хабу"
                }
            }
            
            container "Notification Redis Storage" "Временное хранилище данных состояния уведомлений" {
                tags "cache"
                
                messageHandlers -> this "Сохраняет и извлекает данные пользователей"
                hubs -> this "Сохраняет и извлекает данные подключений"
            }
            
            container "Push Notification Service" "Доставляет push-уведомления пользователям, которые не в сети" {
                tags "push-service"
                
                messageHandlers -> this "Отправляет push-уведомления, когда WebSocket недоступен"
                this -> proxy "Доставляет push-уведомления пользователю"
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
        
        component messengerApi {
            include *
            autolayout lr
        }

        component notifications {
            include *
            autolayout lr
        }

        theme default
        
        styles {
            element "web-app" {
                background "#ffcc99"
                shape "RoundedBox"
                color "#000000"
            }
    
            element "mobile-app" {
                background "#cc99ff"
                shape "RoundedBox"
                color "#000000"
            }
    
            element "proxy" {
                background "#cccccc"
                shape "Box"
                color "#000000"
            }
    
            element "api" {
                background "#99ccff"
                shape "Box"
                color "#000000"
            }
    
            element "microservice" {
                background "#ccffcc"
                shape "Box"
                color "#000000"
            }
    
            element "push-service" {
                background "#669966"
                shape "Box"
                color "#000000"
            }
    
            element "auth-service" {
                background "#99ccff"
                shape "Box"
                color "#000000"
            }
    
            element "message-broker" {
                background "#ffcc00"
                shape "Hexagon"
                color "#000000"
            }
    
            element "cache" {
                background "#ff9999"
                shape "Cylinder"
                color "#000000"
            }
    
            element "database" {
                background "#99cc99"
                shape "Cylinder"
                color "#000000"
            }
    
            element "storage" {
                background "#99ccff"
                shape "Folder"
                color "#000000"
            }
        }
    }

}