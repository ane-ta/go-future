workspace "GoFuture" "Полная модель текущего состояния (As-Is)" {
    !const MODELS_PATH "project/models"
    !const STYLES_PATH "project/styles"

    model {
        !ImpliedRelationships true
        !identifiers hierarchical

        !include ${MODELS_PATH}/landscape.srz

        goFuture = softwareSystem "GoFuture Platform" {
            
            #! Клиентские приложения
            !include ${MODELS_PATH}/ui.srz

            #! Аналитический стек
            !include ${MODELS_PATH}/analytics.srz

            #! Мониторинг и логи
            !include ${MODELS_PATH}/observability.srz

             #! CI/CD
            !include ${MODELS_PATH}/cicd.srz
        }
    }
    views {
        // C1
        // systemLandscape "Landscape" "Описание всей архитектуры" { 
        //     include * 
        //     autolayout lr
        // }
        // // C2
        // container goFuture "Containers" { 
        //     include *
        //     autolayout lr
        // }
        // наблюдаемость
        // container goFuture "Observability" { 
        //     include "->element.tag==Observability->"
        //     autolayout lr
        // }
        // // деплой
        // container goFuture "CiCd" { 
        //     include "->element.tag==CiCd->"
        //     autolayout lr
        // }
        // // аналитика
        // container goFuture "Analytics" { 
        //     include "->element.tag==AnalyticsPipe->"
        //     autolayout lr
        // }

        styles {
            # C1
            !include ${STYLES_PATH}/c1.srz

            # C3
            !include ${STYLES_PATH}/c3.srz

            # Infrastructure
            !include ${STYLES_PATH}/infrastructure.srz

            # prod
            !include ${STYLES_PATH}/prod.srz

            # async
            !include ${STYLES_PATH}/async.srz
        }
    }
}