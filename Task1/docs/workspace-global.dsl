workspace extends workspace-to-be.dsl {
!const MODELS_PATH4 "./global/models"

    model {
        # Обобщенные контейнеры                        
            !include ${MODELS_PATH4}/generalization.srz

        # Репликация региона                         
            !include ${MODELS_PATH4}/region-replication.srz
    }
    views {
        deployment * depRegion {
            include *
            autoLayout lr
        }
        styles {
            element "Standby" {
                background #cccccc
                color #666666
            }
        }
    }
}