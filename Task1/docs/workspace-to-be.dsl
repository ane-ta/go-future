workspace extends ws-parent.dsl {
!const MODELS_PATH3 "./to-be/models"

    model {
    # СИСТЕМА                        
        !element goFuture {

        # Обобщение
            !include ${MODELS_PATH3}/generalization.srz

        # Точка входа
            !include ${MODELS_PATH3}/entrance.srz

        # Очереди и асинхронщина
            mqBg = container "Брокер сообщений репликации" "Очередь задач" "???" "ToBe, Broker"
            mq = container "Брокер сообщений" "Очередь задач" "RabbitMQ" "Broker"

        # Микросервисы
            !include ${MODELS_PATH3}/microservices.srz
            !include ${MODELS_PATH3}/microservices-inner.srz
            !include ${MODELS_PATH3}/microservices-outer.srz
            
        # Миграция на микросервисы
            !include ${MODELS_PATH3}/migration.srz
        }

    # Аналитика
        !include ${MODELS_PATH3}/analytics.srz

    # Наблюдаемость
        !include ${MODELS_PATH3}/observability.srz

    # Деплой
        !include ${MODELS_PATH3}/cicd.srz
  
        # Явные связи для уровня контейнеров (L2)
        // monolith -> dbGeo "Гео поиск водителей" "Elasticsearch API"
        // monolith -> cache "Кеширует данные" "Redis Serialization"
        // monolith -> yandexMaps "Геоданные" "REST"
        // monolith -> yandexPay "Обработка платежей" 
        // monolith -> bankApi "Инициирование выплат" 
        // monolith -> yandexMaps "Запросы геоданных" 

        // workers -> fcm "Отправляет уведомления" "REST API"
        // workers -> apns "Отправляет уведомления" "REST API"
        // workers -> huaweiPush "Отправляет уведомления" "REST API"
        // workers -> bankApi "Выполняет выплаты" "REST API"
    }
    views {

        component monolith "Migration" { 
            include "->element.tag==Entrance"
            include "->element.tag==Migration->"
            include "relationship.tag==Migration"
            autolayout lr
        }

        container goFuture "ProdServices_Data_Interaction" { 
            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            exclude "relationship==*"
            include "relationship.tag==ReplicaLink"

            include "element.tag==Prod && element.tag==Database"
            include mqBg
            autolayout lr
        }

        container goFuture "ProdServices_Logic_Interaction" { 
            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            include "element.tag==External"
            exclude "relationship==*"
            include "relationship.tag==LogicApi"
            include "relationship.tag==ExternalApi"

            autolayout lr
        }

        styles {

        }
    }
}