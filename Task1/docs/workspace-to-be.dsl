workspace extends ws-parent.dsl {
!const MODELS_PATH3 "./to-be/models"
!const VIEWS_PATH3 "./to-be/views"
!const MS_TECHNOLOGY "Python/Faust Streaming"

    model {
    # СИСТЕМА                        

        !element goFuture {

            # Очереди и асинхронщина
                mqEDA = container "Брокер сообщений EDA" "Доменные события, CDC события, события аналитики" "Kafka" "ToBe, Broker"
        }

        # Обобщение
            !include ${MODELS_PATH3}/generalization.srz

        !element goFuture {
            
            # EDA инфраструктура
                validateContract = container "Data Contract / Schema Validation" "Проверяет соответствие схеме (Schema Registry), наличие обязательных полей." "Confluent Schema Registry" "DataQuality"
                msProd -> validateContract "Validate event schema" "gRPC" "Generalization, EDA"
            
            # Точка входа
                !include ${MODELS_PATH3}/entrance.srz
        
            # CDC
                !include ${MODELS_PATH3}/cdc.srz

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

        // микросервисы и репликация CDC
        container goFuture "0101_MS_Data_Interaction" { 
            title "Микросервисы и репликации данных между ними"
            
            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            include "element.tag==Prod && element.tag==Database"
            exclude "element.tag==Generalization"
            include goFuture.replicaAgent
            include goFuture.mqEDA

            exclude "relationship==*"
            include "relationship.tag==ReplicaLink"
            include "relationship.tag==DBLink"

            autolayout tb
        }

        // миграция
        component goFuture.monolith "0102_Migration_to_MS" {
            title "Миграция на микросервисы" 
            include "->element.tag==Entrance"
            include "->element.tag==Migration->"
            include "relationship.tag==Migration"
            include goFuture.msBroker
            autolayout tb
        }

        // EDA
        container goFuture "0201_ProdServices_Logic_Interaction" { 
            title "EDA взаимодействие микросервисов"

            include "element.tag==Prod && element.tag==Service"
            include "element.tag==Prod && element.tag==Worker"
            include goFuture.mqEDA
            include "element.tag==External"
            exclude "element.tag==Generalization"
            
            exclude "relationship==*"
            include "relationship.tag==EDA"
            include "relationship.tag==LogicApi"
            include "relationship.tag==ExternalApi"

            autolayout tb
        }

        // Orchestrator booking happy path
        dynamic goFuture 0202_booking_happy_path "Happy path при создании заказа"{
            properties {
                    "plantuml.sequenceDiagram" "true"
                }
            title "EDA Оркестрация заказа - Happy path при создании заказ"
        
            !include "${VIEWS_PATH3}/Orchestration/booking-created.srz"
            
            !include "${VIEWS_PATH3}/Orchestration/driver-found.srz"

            !include "${VIEWS_PATH3}/Orchestration/ride-completed.srz"
            
            autolayout tb
        }

        // Orchestrator booking when driver not found
        dynamic goFuture 0203_booking_driver_not_found "Водитель не найден при создании заказа"{
            properties {
                    "plantuml.sequenceDiagram" "true"
                }
            title "EDA Оркестрация заказа - Водитель не найден"
        
            !include "${VIEWS_PATH3}/Orchestration/booking-created.srz"
            
            !include "${VIEWS_PATH3}/Orchestration/driver-not-found.srz"
            
            autolayout tb
        }

        // Observability
        container goFuture "0204_Obervability" {
            title "Система обеспечения наблюдаемости"
            include "->element.tag==Observability->"
        }

            // // Driver payouts after booking
            // dynamic goFuture driver_payout "Выплата водителю" {
            //     properties {
            //             "plantuml.sequenceDiagram" "true"
            //         }
            
            //     goFuture.mqEDA -> goFuture.payouts "subscribe: BookingCompleted"
            //     goFuture.payouts -> goFuture.mqEDA "publish: PayoutCompleted"
            // }

        // Аналитика BI & ML
        container goFuture "0401_Analytics" { 
            title "Аналитика BI и ML"
            include "->element.tag==AnalyticsPipe->"
            include "element.tag==Analytics"
            autolayout tb
        }

        // Surge
        dynamic goFuture "0402_SurgeFactor_Update" "Surge" {
            title "Пересчет динамического ценообразования"
            properties {
                    "plantuml.sequenceDiagram" "true"
                }
            
            goFuture.mqEDA -> goFuture.mlPlatform "События для динамического ценообразования"            
            goFuture.mlPlatform -> goFuture.mqEDA "SurgeFactorUpdated"
            goFuture.mqEDA -> goFuture.pricing "SurgeFactorUpdated"
            goFuture.pricing -> goFuture.cachePricing "Surge factor upsert"
            goFuture.mqEDA -> goFuture.analyticsEngine "События для переобучения ML"
        }

        styles {

        }
    }
}