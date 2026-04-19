workspace extends workspace-global.dsl {
!const MODELS_PATH5 "./saas/models"
!const VIEWS_PATH5 "./saas/views"

    model {
        globalAdmin = person "GoFuture Admin" "Сотрудник платформы, управляющий партнерами" "MultiTenant"
        partnerAdmin = person "Partner Admin" "Администратор таксопарка-партнера" "MultiTenant"
        partnerUser = person "Partner user" "Сотрудник таксопарка-партнера" "MultiTenant"

        !element goFuture {
            tenants = container "Partner Management Service" "" "" "MultiTenant"
            onboarding = container "Partner Onboarding Service" "Автоматизация создания новых тенантов" "Go / Python" "MultiTenant"

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
                tenantContext = component "Dynamic DataSource Router" "Задает схему как контекст последующих SQL запросов" "" "MultiTenant"
            }

            # ЛОГИКА ОНБОРДИНГА (Потоки данных)
            globalAdmin -> onboarding "Инициирует создание нового партнера" "" "MultiTenant"
            globalAdmin -> tenants "Создает запись для нового партнера" "" "MultiTenant"
            onboarding -> idService.tenantRealm "Создает Realm и Admin пользователя для партнера\nКонфигурирует SSO для партнера" "gRPC/REST" "MultiTenant"
            onboarding -> msACIDDatabases.tenantSchema "Создает изолированную SQL Schema (CREATE SCHEMA)" "SQL" "MultiTenant"

            # ЛОГИКА ДОСТУПА ПАРТНЕРА
            partnerAdmin -> idService.tenantRealm "Администрирует в свой Realm (SSO)" "" "MultiTenant"
            partnerUser -> idService "Логинится в Realm тенанта (SSO) и получает свой JWT" "" "MultiTenant"
            idService -> partnerUser "Выдает JWT токен с tenant_id" "" "MultiTenant"
            
            partnerUser -> apiGateway.tenantId "Запросы к платформе (с JWT)"
            apiGateway.tenantId -> msProd.tenantContext "Запросы с tenant_id в заголовках" "" "MultiTenant"
            msProd.tenantContext -> msACIDDatabases.tenantSchema "SET search_path TO tenant_schema" "" "MultiTenant"
        }
    }
    views {
        container goFuture "MultitenancyView" {
            include "->element.tag==Entrance"
            include "element.tag==Generalization"
            exclude goFuture.msDatabases
            include "element.tag==MultiTenant"
            exclude "element.tag==Safety"
            include "relationship.tag==MultiTenant"

            autolayout lr
        }

        dynamic goFuture.apiGateway "Onboarding" {
            globalAdmin -> goFuture.tenants
            globalAdmin -> goFuture.onboarding
            goFuture.onboarding -> goFuture.idService.tenantRealm
            goFuture.onboarding -> goFuture.msACIDDatabases.tenantSchema
        }

        dynamic goFuture.apiGateway "Tenant-login" {
            partnerUser -> goFuture.idService
            goFuture.idService -> partnerUser
            partnerUser -> goFuture.apiGateway.tenantId
            goFuture.apiGateway.tenantId -> goFuture.msProd.tenantContext
            goFuture.msProd.tenantContext -> goFuture.msACIDDatabases.tenantSchema 
        }

        styles {
            # Выделяем мультитенантные компоненты синим цветом (или любым другим для отличия)
            element "MultiTenant" {
                background #1168bd
                color #ffffff
                shape RoundedBox
            }
        }
    }
}