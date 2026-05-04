workspace extends workspace-saas.dsl {

    model {
    }
    views {

        properties {
            "c4plantuml.tags" "true"    
        }   
          
        styles {
            element "Container" {
                background #1168bd
                color #ffffff
            }
            // element "Person" {
            //     shape Person
            //     background #08427b
            // }
            element "Infrastructure" {
                background #2c3e50
                stroke #ffffff
            }
            element "GeoRouting" {
                background #23313f
                stroke #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Standby" {
                background #e0e0e0
                color #888888
            }
            element "Database" { 
                shape Cylinder 
                background #1c62b9 
            }
            element "Broker" { 
                shape Pipe 
                background #4b7bec 
            }
            element "Safety" {
                background #c0392b 
                stroke #ffffff
            }
            element "Observability"{
                background #8e44ad 
            }
            element "AnalyticsPipe" {
                background #218c74 
            }

            relationship "Relationship" {
                color #424242
                routing Orthogonal
            }
            relationship "Publish" {
                color #e67e22 
            }
            relationship "Subscribe" {
                color #f1c40f 
            }
        }


    }
}