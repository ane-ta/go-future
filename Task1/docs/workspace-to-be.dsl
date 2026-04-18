workspace extends ws-parent.dsl {
!const MODELS_PATH3 "./to-be/models"
!const VIEWS_PATH3 "./to-be/views"
!const MS_TECHNOLOGY "Python/Faust Streaming"

    model {
    # СИСТЕМА                        
        !element goFuture {

            # Обобщение
                !include ${MODELS_PATH3}/generalization.srz

            # Точка входа
                !include ${MODELS_PATH3}/entrance.srz

            # Очереди и асинхронщина
                mqEDA = container "Брокер сообщений EDA" "Доменные события" "Kafka" "ToBe, Broker"
                mqBg = container "Брокер сообщений репликации" "CDC события" "Kafka" "ToBe, Broker"
                mq = container "Брокер сообщений" "Очередь задач" "RabbitMQ" "Broker"


            # Микросервисы
                !include ${MODELS_PATH3}/microservices.srz
                !include ${MODELS_PATH3}/microservices-inner.srz
                !include ${MODELS_PATH3}/microservices-outer.srz
                
            # Аналитика
                !include ${MODELS_PATH3}/analytics.srz

            # Миграция на микросервисы
                !include ${MODELS_PATH3}/migration.srz

            # Наблюдаемость
                !include ${MODELS_PATH3}/observability.srz

            # Деплой
                !include ${MODELS_PATH3}/cicd.srz
        }
    }
    views {
        // миграция
        component goFuture.monolith "Migration" { 
            include "->element.tag==Entrance"
            include "->element.tag==Migration->"
            include "relationship.tag==Migration"
            autolayout lr
        }

        // микросервисы и репликация CDC
        container goFuture "ProdServices_Data_Interaction" { 
            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            exclude "relationship==*"
            include "relationship.tag==ReplicaLink"

            include "element.tag==Prod && element.tag==Database"
            include goFuture.mqBg
            autolayout lr
        }

        // EDA
        container goFuture "ProdServices_Logic_Interaction" { 
            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            include goFuture.mqEDA
            include "element.tag==External"
            exclude "relationship==*"
            include "relationship.tag==EDA"
            include "relationship.tag==LogicApi"
            include "relationship.tag==ExternalApi"

            autolayout lr
        }

        // Observability
        container goFuture "Obervability" {
            include "->element.tag==Observability->"
        }
        // Surge
        dynamic goFuture Surge " Surge" {
            properties {
                    "plantuml.sequenceDiagram" "true"
                }
            
            // goFuture.mqEDA -> goFuture.analyticsEngine "События для динамического ценообразования"
            // goFuture.analyticsEngine -> goFuture.mqEDA "SurgeFactorUpdated"
            goFuture.mqEDA -> goFuture.pricing "SurgeFactorUpdated"
            goFuture.pricing -> goFuture.cachePricing "Surge factor upsert"
        }

        // Orchestrator booking happy path
        dynamic goFuture booking_happy_path "Happy path при создании заказа"{

            properties {
                    "plantuml.sequenceDiagram" "true"
                }
        
            !include "${VIEWS_PATH3}/Orchestration/booking-created.srz"
            
            !include "${VIEWS_PATH3}/Orchestration/driver-found.srz"

            !include "${VIEWS_PATH3}/Orchestration/ride-completed.srz"
            
            autolayout lr
        }
        // Driver payouts after booking
        dynamic goFuture driver_payout "Выплата водителю"{
            properties {
                    "plantuml.sequenceDiagram" "true"
                }
        
            goFuture.mqEDA -> goFuture.payouts "subscribe: BookingCompleted"
            goFuture.payouts -> goFuture.mqEDA "publish: PayoutCompleted"
        }

        // Orchestrator booking when driver not found
        dynamic goFuture booking_driver_not_found "Водитель не найден при создании заказа"{

            properties {
                    "plantuml.sequenceDiagram" "true"
                }
        
            !include "${VIEWS_PATH3}/Orchestration/booking-created.srz"
            
            !include "${VIEWS_PATH3}/Orchestration/driver-not-found.srz"
            
            autolayout lr
        }

        // аналитика
        container goFuture "Analytics" { 
            title "Аналитика"
            include "->element.tag==AnalyticsPipe->"
            include "element.tag==Analytics"
            autolayout lr
        }
        styles {

        }
    }
}