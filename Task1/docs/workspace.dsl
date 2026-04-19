workspace extends workspace-saas.dsl {

    model {
    }
    views {
        styles {
            # БАЗОВЫЕ ЭЛЕМЕНТЫ
            element "Element" {
                background #000000
                color #fffffe
            }
            element "Person" {
                background #08427b
            }
            element "External" { 
                background #999999 
            }

            # ИНФРАСТРУКТУРА И СЛОИ
            element "Infrastructure" {
                background #555555
                shape RoundedBox
            }
            element "CiCd" {
                background #444444 
            }
            element "GeoRouting" {
                background #2c3e50
            }

            # ПРОДАКШЕН И БИЗНЕС-ЛОГИКА
            element "Prod" { 
                background #1168bd 
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Standby" {
                background #e0e0e0
                color #888888
            }

            # ХРАНИЛИЩА (Берем оттенки синего и бирюзового)
            element "Database" { 
                shape Cylinder 
                background #1c62b9 
            }
            element "Cache" { 
                background #3498db
                shape Cylinder
            }

            # СПЕЦИАЛЬНЫЕ ЗОНЫ (Акценты)
            element "Broker" { 
                shape Pipe 
                background #4b7bec 
            }
            element "Safety" {
                background #c0392b 
                // Приглушенный красный
            }
            element "MultiTenant" {
                background #2980b9
                shape RoundedBox
            }

            # DATA / ANALYTICS / MONITORING
            element "AnalyticsPipe" {
                background #218c74 
                //# Глубокий изумрудный вместо болотного
            }
            element "Observability"{
                background #8e44ad 
                //# Приглушенный фиолетовый вместо фуксии
            }

            # СВЯЗИ (Убираем "ядерные" цвета, делаем их спокойнее)
            relationship "Relationship" {
                dashed false
                thickness 2
            }
            relationship "Publish" {
                color #e67e22 
                //# Спокойный оранжевый
            }
            relationship "Subscribe" {
                color #f1c40f 
                //# Приглушенный золотой
            }
            relationship "LogicApi" {
                color #ADBEBF 
                //# Серый для логики
            }
        }
    }
}