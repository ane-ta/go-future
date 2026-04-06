workspace "GoFuture" "Полная модель текущего состояния (As-Is)" {

    model {
        #! --- 1. АКТОРЫ (из C1/C2) ---
        passenger = person "Пассажир" "Заказывает, отслеживает и оплачивает поездки"
        driver = person "Водитель" "Принимает заказы и получает выплаты"
        corpManager = person "Корпоративный менеджер" "Управляет счетами и поездками"
        accountant = person "Бухгалтер" "Контролирует выплаты водителям"
        #?
        dev = person "Разработчик" "Разрабатывает новые функции"
        sre = person "SRE инженер" "Мониторинг и поддержка" "Internal"

        #! --- 2. ВНЕШНИЕ СИСТЕМЫ (из C1) ---
        yandexPay = softwareSystem "Яндекс Пэй" "Платежный шлюз" "External"
        yandexMaps = softwareSystem "Яндекс Карты" "Геоданные и маршруты" "External"
        bankApi = softwareSystem "API Банка" "Банковские выплаты" "External"
        fcm = softwareSystem "Firebase Cloud Messaging" "Push iOS/Android" "External"
        apns = softwareSystem "Apple Push Notification" "Push iOS" "External"
        huaweiPush = softwareSystem "Huawei Push Kit" "Push Huawei" "External"

        # --- 3. СИСТЕМА GOFUTURE ---
        goFuture = softwareSystem "GoFuture Platform" {
            
            #! Клиентские приложения
            webPassenger = container "Пассажирское приложение" "iOS/Android/Huawei" "Native"
            webDriver = container "Водительское приложение" "iOS/Android/Huawei" "Native"
            webPortal = container "Корпоративный веб-портал" "Web Application"
            adminPortal = container "Админ-панель" "Web Application"

            # Основной монолит и его внутренние домены (из C3)
            monolith = container "GoFuture Monolith" "Django Application" "Python" {
                booking = component "Booking Domain" "Управление бронированиями"
                driverDom = component "Driver Domain" "Управление водителями"
                pricing = component "Pricing Domain" "Ценообразование"
                payments = component "Payments Domain" "Платежи от пассажиров"
                payouts = component "Payouts Domain" "Выплаты водителям"
                notif = component "Notification Domain" "Управление уведомлениями"
                geo = component "Geography Domain" "Геопоиск и маршрутизация"
                analyticsDom = component "Analytics Domain" "Сбор аналитики"
                fraud = component "Fraud Domain" "Обнаружение мошенничества"
            }

            #! Хранилища
            dbMain = container "Основная БД" "PostgreSQL RDS" "Database"
            dbGeo = container "GEO Drivers search DB" "Elasticsearch" "Database"
            cache = container "In-memory кеш" "Redis" "Database"

            #! Очереди и асинхронщина
            mq = container "RabbitMQ" "Брокер сообщений" "Erlang" "Broker"
            workers = container "Celery Workers" "Асинхронная обработка" "Python"

            #! Аналитический стек
            analyticsEngine = container "Analytics Engine" "Spark/Flink"
            dbAnalytics = container "Analytics Db" "ClickHouse" "Database"
            dataLens = container "DataLens" "BI Tool"

            #! Мониторинг и логи
            prometheus = container "Prometheus" "Сбор метрик"
            grafana = container "Grafana" "Визуализация"
            alertManager = container "Alertmanager" "Алертинг"
            loki = container "Loki" "Сбор логов"

            #! CI/CD
            jenkins = container "Jenkins" "Automation Server"
            artifactRepo = container "Artifact Repository" "Docker Registry"
            #??? Container(ci_worker, "CI/CD Workers", "VM/Containers", "Выполнение задач сборки и тестов")
        }

        # --- СВЯЗИ (Relationships) ---

        # Взаимодействие пользователей
        passenger -> webPassenger "Использует"
        driver -> webDriver "Использует"
        corpManager -> webPortal "Использует"
        accountant -> adminPortal "Использует"

        # Клиенты -> Монолит
        webPassenger -> monolith "API запросы" "HTTPS"
        webDriver -> monolith "API запросы" "HTTPS"
        webPortal -> monolith "Управление заказами" "HTTPS"
        adminPortal -> monolith "Управление выплатами" "HTTPS"

        # Прямые SQL запросы доменов (из твоего C3)
        booking -> dbMain "SQL: bookings, drivers"
        driverDom -> dbMain "SQL: drivers, payouts"
        pricing -> dbMain "SQL: pricing_rules"
        payments -> dbMain "SQL: payments"
        payouts -> dbMain "SQL: payouts"
        geo -> dbMain "SQL: drivers, zones"
        analyticsDom -> dbMain "SQL: все таблицы"
        fraud -> dbMain "SQL: payments, bookings"

        # Внутренние вызовы монолита
        booking -> driverDom "назначает" "синхронно"
        booking -> pricing "запрашивает цену" "синхронно"
        booking -> payments "инициирует оплату" "синхронно"
        booking -> geo "ищет водителей" "синхронно"

        # Асинхронные задачи (через MQ)
        monolith -> mq "Публикует задачи" "AMQP"
        mq -> workers "Передает задачи" "AMQP"
        
        workers -> yandexPay "Платежи" "REST API"
        workers -> bankApi "Выплаты" "REST API"
        workers -> fcm "Push"
        workers -> apns "Push"
        workers -> huaweiPush "Push"
        workers -> dbMain "Записывает результаты" "SQL"

        # Аналитический пайплайн (из C3)
        analyticsDom -> mq "отправка событий" "AMQP"
        analyticsEngine -> dbAnalytics "ETL"
        dbAnalytics -> dataLens "SQL"
        dataLens -> corpManager "Смотрит отчеты"

        # Мониторинг и Логи (из C2)
        monolith -> prometheus "Метрики"
        workers -> prometheus "Метрики"
        dbMain -> prometheus "Метрики (Exporter)"
        mq -> prometheus "Метрики (Exporter)"
        monolith -> loki "Логи"
        prometheus -> alertManager "Алерты"
        alertManager -> sre "Уведомления"

        # CI/CD
        jenkins -> artifactRepo "Управление образами"
        artifactRepo -> monolith "Хранение образов"
        dev -> jenkins "Пушит код"

        # Явные связи для уровня контейнеров (L2)
        monolith -> dbMain "Читает/Пишет" "SQL"
        monolith -> dbGeo "Поиск водителей" "Elasticsearch API"
        monolith -> cache "Кеширует данные" "Redis Serialization"
        monolith -> yandexMaps "Геоданные" "REST"

        # Добавь связи для воркеров, чтобы они не висели в воздухе на L2
        // workers -> yandexPay "Проводит оплату"
        // workers -> bankApi "Делает выплаты"
    }

    views {
        systemContext goFuture "AsIs_Context" { 
            include * 
            autolayout lr
        }

        container goFuture "AsIs_Containers" { 
            include *
            autolayout
        }
        component monolith "AsIs_Components" { 
            include * 
            autolayout lr
        }

        styles {
            element "External" { 
                background #999999 
                color #ffffff 
            }
            element "Database" { 
                shape Cylinder 
                background #f5da81 
            }
            element "Broker" { 
                shape Pipe 
                background #85bbf0 
            }
        }
    }
}