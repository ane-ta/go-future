workspace extends workspace-to-be.dsl {
!const MODELS_PATH4 "./global/models"
!const VIEWS_PATH4 "./global/views"

    model {
        # Обобщенные контейнеры                        
            !include ${MODELS_PATH4}/generalization.srz

        # Резервирование региона                         
            !include ${MODELS_PATH4}/region-fails.srz

        # Репликация региона                         
            !include ${MODELS_PATH4}/region-replication.srz
    }
    views {

        # Реплицирование региона                         
            !include ${VIEWS_PATH4}/region-replication-views.srz

        # Резервирование региона                         
            !include ${VIEWS_PATH4}/region-fails-views.srz

        styles {
            // element "Standby" {
            //     background #cccccc
            //     color #666666
            // }
            
            // element "Infrastructure" {
            //     background #546B57
            //     shape RoundedBox
            // }
            // element "GeoRouting" {
            //     background #17561F
            // }
            // element "Safety" {
            //     background #B43131
            // }
        }
    }
}