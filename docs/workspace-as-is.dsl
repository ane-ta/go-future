workspace extends workspace-parent.dsl {
    !const MODELS_PATH2 "./as-is/models"

    model {

        # --- 3. СИСТЕМА GOFUTURE ---
        !element goFuture {
            
            #! Хранилища
            dbMain = container "Основная БД" "Хранит все бизнес данные" "PostgreSQL RDS" "Database"
            dbGeo = container "GEO Drivers search DB" "Поисковый индекс" "Elasticsearch" "Database"
            cache = container "In-memory кеш" "Кеширование данных" "Redis" "Database"

            #! Очереди
            mq = container "Брокер сообщений" "Очередь задач" "RabbitMQ" "Broker, Analytics"

            !include ${MODELS_PATH2}/domains.srz
            !include ${MODELS_PATH2}/domains-inners.srz
            !include ${MODELS_PATH2}/domains-outers.srz
            
            !include ${MODELS_PATH2}/workers.srz
            !include ${MODELS_PATH2}/workers-outers.srz

            !include ${MODELS_PATH2}/analytics.srz
            !include ${MODELS_PATH2}/observability.srz
            !include ${MODELS_PATH2}/cicd.srz
        }
    }
    views {
    // домены внешние взаимодействия
        component goFuture.monolith "Monolith-Outer-Interactions" { 
            include * 
            exclude "element.tag==Database"

            exclude "element.tag==Observability"
            exclude "element.tag==CiCd"
            autolayout lr
        }

    // домены внутренние взаимодействия
        component goFuture.monolith "Monolith-Inner-Interactions" { 
            include *
            exclude "element.tag==External"
            exclude "element.tag==Broker"
            exclude "element.tag==Analytics"
            
            exclude "element.tag==Observability"
            exclude "element.tag==CiCd"
            autolayout lr
        }

    // воркеры
        component goFuture.workers "Workers" { 
            include * 
            autolayout lr
        }

    // наблюдаемость
        container goFuture "Observability" { 
            include "->element.tag==Observability->"
            autolayout lr
        }
        dynamic goFuture.monolith "Observability_Components" {
            goFuture.monolith.booking -> goFuture.loki
            goFuture.monolith.payments -> goFuture.loki
            goFuture.workers.notificationTasks -> goFuture.loki
            goFuture.workers.payoutTasks -> goFuture.loki

            goFuture.monolith.booking -> goFuture.prometheus
            goFuture.monolith.payments -> goFuture.prometheus
            goFuture.workers.notificationTasks -> goFuture.prometheus
            goFuture.workers.payoutTasks -> goFuture.prometheus

            autolayout lr
        }
    // C1
        systemLandscape "Landscape" "Описание всей архитектуры" { 
            include * 
            autolayout lr
        }
    // C2
        container goFuture "Containers" { 
            include *
            autolayout lr
        }

    // деплой
        container goFuture "CiCd" { 
            include "->element.tag==CiCd->"
            autolayout lr
        }
    // аналитика
        container goFuture "Analytics" { 
            include "element.tag==Analytics"
            include "->element.tag==AnalyticsPipe->"
            exclude "relationship.tag!=Analytics && relationship.tag!=AnalyticsPipe"
            autolayout lr
        }

    // эксперимент
        dynamic goFuture.monolith "OrderProcess" "Сквозной процесс заказа" {
            goFuture.monolith.booking -> goFuture.monolith.geo "1. Ищет маршрут"
            goFuture.monolith.booking -> goFuture.mq "2. Публикует событие"
            goFuture.mq -> goFuture.workers.notificationTasks "3. Забирает задачу"
            goFuture.workers.notificationTasks -> fcm "4. Отправляет Push"

            autolayout lr
        }

        styles {

        }
    }
}