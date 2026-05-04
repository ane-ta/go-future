workspace extends workspace-global.dsl {
!const MODELS_PATH5 "./saas/models"
!const VIEWS_PATH5 "./saas/views"

    model {
        globalAdmin = person "GoFuture Admin" "Сотрудник платформы, управляющий партнерами" 
        partnerAdmin = person "Partner Admin" "Администратор таксопарка-партнера" 
        partnerUser = person "Partner user" "Сотрудник таксопарка-партнера" 

        !element goFuture {
            group MultiTenancy {
                tenants = container "Partner Management Service" "" "" "MultiTenant"
                onboarding = container "Partner Onboarding Service" "Автоматизация создания новых тенантов" "Go / Python" "MultiTenant"
            }

            !element idService {
                tenantRealm = component "Tenant realm" "" "" "MultiTenant"
            }
            !element msACIDDatabases {
                tenantSchema = component "Partner database schema" "Хранение данных партнеров в изолированных схемах (Schema-per-tenant)" "PostgreSQL" "MultiTenant"
            }
            !element apiGateway {
                tenantId = component "Tenant Id из JWT" "Извлекает tenant_id из JWT и помещение его в заголовок" "" "MultiTenant"
            }
            !element msProd {
                tenantContext1 = component "Dynamic DataSource Router" "Задает схему как контекст последующих SQL запросов" "" "MultiTenant"
                tenantContext2 = component "Event Publisher" "Передает в событиях tenant_id" "" "MultiTenant"
            }

            # ЛОГИКА ОНБОРДИНГА (Потоки данных)
            globalAdmin -> onboarding "Инициирует создание нового партнера" "" "MultiTenant"
            globalAdmin -> tenants "Создает запись для нового партнера" "" "MultiTenant"
            onboarding -> idService.tenantRealm "Создает Realm и Admin учетку для партнера\nКонфигурирует SSO для партнера" "gRPC" "MultiTenant"
            onboarding -> msACIDDatabases.tenantSchema "Создает изолированную SQL Schema (CREATE SCHEMA)" "SQL" "MultiTenant"

            # ЛОГИКА ДОСТУПА ПАРТНЕРА
            globalAdmin -> idService "Администрирует" "" "MultiTenant"
            partnerAdmin -> idService.tenantRealm "Администрирует свой Realm (SSO)" "" "MultiTenant"
            partnerUser -> idService "Логинится в Realm тенанта (SSO) и получает свой JWT" "" "MultiTenant"
            idService -> partnerUser "Выдает JWT токен с tenant_id" "" "MultiTenant"
            
            partnerUser -> apiGateway.tenantId "Запросы к платформе (с JWT)"
            apiGateway.tenantId -> msProd.tenantContext1 "Запросы с tenant_id в заголовках" "" "MultiTenant"
            msProd.tenantContext1 -> msACIDDatabases.tenantSchema "SET search_path TO tenant_schema" "" "MultiTenant"

            apiGateway.tenantId -> msProd.tenantContext2 "Запросы с tenant_id в заголовках" "" "MultiTenant"
            msProd.tenantContext2 -> mqEDA "Публикует все события с tenant_id" "Publish" "MultiTenant"
        }
    }
    views {
        // Мультитенантность???
//         container goFuture "0501_MultitenancyView" {
//             title "Мультитенантность"

// //            include "->element.tag==Entrance"
//             include "element.tag==Generalization"
//             exclude goFuture.msDatabases
//             exclude "element.tag==Safety"
//             exclude "element.tag==Migration"

//             include goFuture.apiGateway
//             include goFuture.alloy
//             include "element.tag==MultiTenant"

//             exclude "relationship==*"

//             include "relationship.tag==MultiTenant"

//             autolayout lr
//         }
        // Создание окружения для нового партнера
        dynamic goFuture.apiGateway "0502_Onboarding" {
            title "Создание окружения для нового партнера"
            properties {
                "plantuml.sequenceDiagram" "true"
            }
                        
            globalAdmin -> goFuture.tenants
            globalAdmin -> goFuture.onboarding
            goFuture.onboarding -> goFuture.idService.tenantRealm
            goFuture.onboarding -> goFuture.msACIDDatabases.tenantSchema
        }

        // Обработка запроса для партнера
        dynamic goFuture.apiGateway "0503_Tenant-login" {
            title "Обработка запроса для партнера"
            properties {
                "plantuml.sequenceDiagram" "true"
            }
            partnerUser -> goFuture.idService
            goFuture.idService -> partnerUser
            partnerUser -> goFuture.apiGateway.tenantId
            goFuture.apiGateway.tenantId -> goFuture.msProd.tenantContext1
            goFuture.msProd.tenantContext1 -> goFuture.msACIDDatabases.tenantSchema 
            goFuture.apiGateway.tenantId -> goFuture.msProd.tenantContext2
            goFuture.msProd.tenantContext2 -> goFuture.mqEDA 
        }

        styles {
            # Выделяем мультитенантные компоненты синим цветом (или любым другим для отличия)
            // element "MultiTenant" {
            //     background #1168bd
            //     color #ffffff
            //     shape RoundedBox
            // }
        }
    }
}