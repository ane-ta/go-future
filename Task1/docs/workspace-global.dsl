workspace extends workspace-to-be.dsl {
!const MODELS_PATH4 "./global/models"

    model {
        # Обобщенные контейнеры                        
            !include ${MODELS_PATH4}/generalization.srz

        # Репликация региона                         
            !include ${MODELS_PATH4}/region-replication.srz
        
        globalInfra = softwareSystem "Global Infrastructure" {
            tags "Infrastructure"
        
        
            geoDns = container "GeoDNS (Route 53)" {
                description "DNS-маршрутизация на основе геолокации и задержки"
                technology "AWS Route 53"
                tags "Infrastructure, GeoRouting"
            }

            // Health Checker (может быть частью Route 53)
            healthChecker = container "Health Checker" {
                description "Мониторинг доступности регионов"
                technology "AWS Route 53 Health Checks"
                tags "Infrastructure"
            }

            // Глобальный балансировщик (опционально, если используешь Anycast)
            // globalBalancer = container "Global Load Balancer" {
            //     description "Глобальный балансировщик с Anycast"
            //     technology "AWS Global Accelerator / Cloudflare"
            //     tags "Infrastructure"
            // }

            geoDns -> healthChecker "использует для определения доступности"
            //geoDns -> globalBalancer "может направлять на глобальный IP"
            geoDns -> apiGateway "направляет трафик в развертывание"
        }
        
        healthChecker -> apiGateway "health check: GET /health" "HTTPS"
        apiGateway -> msACIDDatabases "health check: SELECT 1" 
        apiGateway -> msBroker "health check: metadata fetch" 

        globalDeployment = deploymentEnvironment "Global Infrastructure" {
            singaporeDG = deploymentGroup "Singapore"
            jakartaDG = deploymentGroup "Jakarta"

            deploymentNode "AWS Global" {
                containerInstance geoDns singaporeDG,jakartaDG
                containerInstance healthChecker singaporeDG,jakartaDG
             //   containerInstance globalBalancer singaporeDG,jakartaDG
            }


            singaporeDeployment = deploymentNode "Singapore Region" {
                deploymentNode "Kubernetes Cluster" {
                    containerInstance apiGateway singaporeDG
                    containerInstance msProd singaporeDG
                    containerInstance msBroker singaporeDG
                    containerInstance msACIDDatabases singaporeDG
                }
            }
            jakartaDeployment  = deploymentNode "Jakarta Region" {
                deploymentNode "Kubernetes Cluster" {
                    containerInstance apiGateway jakartaDG
                    containerInstance msProd jakartaDG
                    containerInstance msBroker jakartaDG
                    containerInstance msACIDDatabases jakartaDG
                }
            }
        }
        user = person "Пользователь (Индонезия)"
        user -> GeoDNS
        user -> apiGateway

    }
    views {
        deployment * depRegion {
            include *
            exclude "element.tag==Migration"
            autoLayout lr
        }

        deployment * globalDeployment {
            title "Глобальная инфраструктура (GeoDNS)"
            description "Схема геомаршрутизации и глобального балансирования"
            include *
            autolayout lr
        }

        dynamic globalInfra "GeoRoutingSuccess" "Геомаршрутизация: успех" {
            
            user -> geoDns "DNS-запрос: api.gofuture.com"
            geoDns -> healthChecker "проверяет доступность регионов"
            healthChecker -> geoDns "Джакарта доступна"
            geoDns -> user "IP Джакарты (15.185.0.1)"
            user -> apiGateway "HTTP-запрос в Джакарта"
            apiGateway -> msProd "прокси в микросервисы"
            
            autolayout lr
        }

        dynamic globalInfra "GeoRoutingFailover" "Геомаршрутизация: отказ региона" {
            
            user -> geoDns "DNS-запрос: api.gofuture.com"
            geoDns -> healthChecker "проверяет доступность Сингапура"
            healthChecker -> geoDns "Сингапур НЕ ДОСТУПЕН"
            geoDns -> user "IP Куала-Лумпур (резервный регион)"
            user -> apiGateway "HTTP-запрос в Куала-Лумпур"
            apiGateway -> msProd "прокси в микросервисы"
            
            autolayout lr
        }

        styles {
            element "Standby" {
                background #cccccc
                color #666666
            }
            
            element "Infrastructure" {
                background #546B57
                shape RoundedBox
            }
            element "GeoRouting" {
                background #17561F
            }

        }
    }
}