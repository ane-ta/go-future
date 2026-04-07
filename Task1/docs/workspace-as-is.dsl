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
            webPortal = container "Корпоративный веб-портал" "Web Application" "Native"
            adminPortal = container "Админ-панель" "Управление выплатами" "Web Application" "Native"

            # Основной монолит и его внутренние домены (из C3)
            monolith = container "GoFuture Monolith" "Django Application" "Python" {
                booking = component "Booking Domain" "Управление бронированиями" "Django App"
                driverDom = component "Driver Domain" "Управление водителями" "Django App"
                pricing = component "Pricing Domain" "Ценообразование" "Django App"
                payments = component "Payments Domain" "Платежи от пассажиров" "Django App"
                payouts = component "Payouts Domain" "Выплаты водителям" "Django App"
                notif = component "Notification Domain" "Управление уведомлениями" "Django App"
                geo = component "Geography Domain" "Геопоиск и маршрутизация" "Django App"
                analyticsDom = component "Analytics Domain" "Сбор аналитики" "Django App"
                fraud = component "Fraud Domain" "Обнаружение мошенничества" "Django App"
            }

            #! Хранилища
            dbMain = container "Основная БД" "Хранит все бизнес данные" "PostgreSQL RDS" "Database"
            dbGeo = container "GEO Drivers search DB" "Поисковый индекс" "Elasticsearch" "Database"
            cache = container "In-memory кеш" "Кеширование данных" "Redis" "Database"

            #! Очереди и асинхронщина
            mq = container "Брокер сообщений" "Очередь задач" "RabbitMQ" "Broker"
            workers = container "Воркеры фоновых задач" "Обработка асинхронных задач" "Celery"{
                payoutTasks = component "Payout Tasks" "Асинхронные задачи выплат" "Celery Task"
                notificationTasks = component "Notification Tasks" "Асинхронные задачи уведомлений" "Celery Task"
                analyticsTasks = component "Analytics Tasks" "Асинхронная аналитика" "Celery Task"
            }

            #! Аналитический стек
            analyticsEngine = container "Analytics Engine" "Обработка аналитических данных" "Spark/Flink" "Analytics"
            dbAnalytics = container "Analytics Db" "Хранение аналитических данных" "ClickHouse" "Analytics"
            dataLens = container "DataLens" "Визуализация бизнес метрик" "BI Tool" "Analytics"

            #! Мониторинг и логи
            prometheus = container "Prometheus" "Сбор метрик и мониторинг" "Monitoring system"  "Observability"
            grafana = container "Grafana" "Визуализация метрик. Дашборды"  "Grafana" "Observability"
            alertManager = container "Alertmanager" "Алертинг"  "Alertmanager"  "Observability"
            loki = container "Loki" "Сбор логов"  "Loki" "Observability"        

            #! CI/CD
            jenkins = container "Jenkins" "Сборка и деплой" "CI/CD" "CiCd"
            artifactRepo = container "Artifact Repository" "Хранение образов" "Docker Registry" "CiCd"
            cicdWorker = container "CI/CD Workers" "Выполнение задач сборки и тестов" "VM/Containers" "CiCd"
        }

        # --- СВЯЗИ (Relationships) ---

        # Взаимодействие пользователей
        passenger -> webPassenger "Использует"
        driver -> webDriver "Использует"
        corpManager -> webPortal "Использует"
        accountant -> adminPortal "Использует"

        # Клиенты -> Монолит
        webPassenger -> monolith "REST API" "HTTPS"
        webDriver -> monolith "REST API" "HTTPS"
        webPortal -> monolith "REST API" "HTTPS"
        adminPortal -> monolith "REST API" "HTTPS"
            #C3
            webPassenger -> booking "Создает заказы" "HTTPS"
            webDriver -> driverDom "Обновляет статус" "HTTPS"
            webPortal -> booking "Просмотр заказов" "HTTPS"
            adminPortal -> payouts "Управление выплатами" "HTTPS"

            # C3 Прямые SQL запросы доменов 
            booking -> dbMain "bookings, drivers" "SQL"
            driverDom -> dbMain "drivers, payouts" "SQL"
            pricing -> dbMain "pricing_rules" "SQL"
            payments -> dbMain "payments" "SQL"
            payouts -> dbMain "payouts" "SQL"
            geo -> dbMain "drivers, zones" "SQL"
            analyticsDom -> dbMain "все таблицы" "SQL"
            fraud -> dbMain "payments, bookings" "SQL"

            geo -> dbGeo "поиск водителей" "Elasticsearch API"
            
            # C3 Кеширование
            pricing -> cache "кеш ценовых правил" "Redis"
            notif -> cache "кеш устройств" "Redis"
            geo -> cache "кеш геоданных" "Redis"
            
            # C3 Внутренние вызовы монолита
            booking -> driverDom "назначает водителя" "синхронно"
            booking -> pricing "запрашивает цену" "синхронно"
            booking -> payments "инициирует оплату" "синхронно"
            booking -> geo "ищет маршрут" "синхронно"
            booking -> fraud "проверяет на мошенничество" "синхронно"
            booking -> notif "отправляет уведомления" "синхронно"

            driverDom -> pricing "расчет заработка" "синхронно"
            payments -> fraud "проверка транзакций" "синхронно"
            payouts -> driverDom "данные водителя" "синхронно"
            geo -> analyticsDom "метрики геопоиска" "синхронно"

            # C3 ASYNC-связи
            booking -> mq "уведомления и аналитика" "AMQP"
            payouts -> mq "выплаты" "AMQP"
            payments -> mq "отчеты" "AMQP"
            analyticsDom -> mq "события аналитики" "AMQP"

            # C3 Внешние интеграции
            geo -> yandexMaps "геоданные" "Yandex Maps API"
            payments -> yandexPay "платежи" "Yandex Pay API"
            


        # Асинхронные задачи (через MQ)
        monolith -> mq "Публикует задачи" "AMQP"
        mq -> workers "Передает задачи" "AMQP"
        
        workers -> yandexPay "Платежи" "REST API"
        workers -> bankApi "Выплаты" "REST API"
        workers -> fcm "Push"
        workers -> apns "Push"
        workers -> huaweiPush "Push"
        workers -> dbMain "Записывает результаты" "SQL"
        workers -> loki "Отправляет логи" "Loki logs"

            # C3 Асинхронные задачи
            mq -> payoutTasks "Задачи выплат" "AMQP"
            mq -> notificationTasks "Задачи уведомлений" "AMQP"
            mq -> analyticsTasks "Задачи аналитики" "AMQP"
            
            # C3 Внешние сервисы
            payoutTasks -> bankApi "Банковские выплаты" "REST API"
            notificationTasks -> fcm "Уведомления Android" "REST API"
            notificationTasks -> huaweiPush "Уведомления Huawei" "REST API"
            notificationTasks -> apns "Уведомления iOS" "REST API"

            # C3 Хранилища
            notificationTasks -> dbMain "данные уведомлений" "ORM"
            payoutTasks -> dbMain "выплаты и балансы" "ORM"
            analyticsTasks -> dbMain "аналитические данные" "ORM"

        # Аналитический пайплайн
        # C2
        monolith -> analyticsEngine  "Отправка событий" "AMQP"
        workers -> analyticsEngine  "Отправка событий" "AMQP"
        analyticsEngine -> dbAnalytics "Записывает данные" "ETL"
        dbAnalytics -> dataLens "Предоставляет данные" "SQL"
        dataLens -> corpManager "Смотрит отчеты"

            # C3
            analyticsDom -> mq "Отправка событий" "AMQP"
            analyticsDom -> analyticsEngine "Отправка событий" "AMQP"
            analyticsTasks -> analyticsEngine "обработка данных" "Spark Jobs"

        # Мониторинг 
        # C2
        monolith -> prometheus "Метрики" "Prometheus metrics"
        workers -> prometheus "Метрики" "Prometheus metrics"
        dbMain -> prometheus "Метрики БД" "PostgreSQL Exporter"
        mq -> prometheus "Метрики очередей" "RabbitMQ Exporter"

        prometheus -> grafana "Предоставляет данные"   "PromQL"
        prometheus -> alertManager "Алерты"
        alertManager -> sre "Уведомления" "Email/Slack/Pager"
        sre -> alertManager "Настраивает алерты"
        sre -> grafana "Мониторит систему"

            # C3 monolith
            booking -> prometheus "метрики бронирований" "Prometheus"
            payments -> prometheus "метрики платежей" "Prometheus"

            # C3 workers
            notificationTasks -> prometheus "метрики уведомлений" "Prometheus"
            payoutTasks -> prometheus "метрики выплат" "Prometheus"

        # Логи
        # C2
        monolith -> loki "Отправляет логи" "Loki Logs"

            # C3 monolith
            booking -> loki "логи бронирований" "Loki Logs"
            payments -> loki "логи платежей" "Loki Logs"

            # C3 workers
            notificationTasks -> loki "Логи уведомлений" "Loki Logs"
            payoutTasks -> loki "Логи выплат" "Loki Logs"
            # ? analyticsTasks -> loki "Логи аналитики" "Loki Logs"


        # CI/CD
        jenkins -> artifactRepo "Управление образами" "Docker API"
        dev -> jenkins "Пушит код"
        jenkins -> cicdWorker "Запускает задачи" "SSH/API"
        cicdWorker -> artifactRepo "Пушит образы" "Docker Push"
        cicdWorker -> monolith "деплой приложения" "Docker Deploy"
        cicdWorker -> workers "деплой воркеров" "Docker Deploy"

        # Явные связи для уровня контейнеров (L2)
        monolith -> dbMain "Читает/Пишет" "ORM"
        workers -> dbMain "Читает/Пишет" "ORM"
        monolith -> dbGeo "Гео поиск водителей" "Elasticsearch API"
        monolith -> cache "Кеширует данные" "Redis Serialization"
        monolith -> yandexMaps "Геоданные" "REST"
        monolith -> yandexPay "Обработка платежей" 
        monolith -> bankApi "Инициирование выплат" 
        monolith -> yandexMaps "Запросы геоданных" 
        # Добавь связи для воркеров, чтобы они не висели в воздухе на L2

        workers -> fcm "Отправляет уведомления" "REST API"
        workers -> apns "Отправляет уведомления" "REST API"
        workers -> huaweiPush "Отправляет уведомления" "REST API"
        workers -> bankApi "Выполняет выплаты" "REST API"
    }
    views {
        systemContext goFuture "AsIs_Context" { 
            include * 
            autolayout lr
        }

        container goFuture "AsIs_Containers" { 
            include *
            autolayout lr
        }
        component monolith "AsIs_Monolith_Components" { 
            include * 
            autolayout lr
        }
        component monolith "AsIs_Monolith_Inner" { 
            include *
            exclude "element.tag==External"
            exclude "element.tag==Database"
            exclude "element.tag==Broker"
            exclude "element.tag==Observability"
            exclude "element.tag==CiCd"
            exclude "element.tag==Analytics"
            autolayout lr
        }

        component workers "AsIs_Worker_Components" { 
            include * 
            autolayout lr
        }

        dynamic monolith "OrderProcess" "Сквозной процесс заказа" {
            booking -> geo "1. Ищет маршрут"
            booking -> mq "2. Публикует событие"
            mq -> notificationTasks "3. Забирает задачу"
            notificationTasks -> fcm "4. Отправляет Push"

            autolayout lr
        }

        styles {
            element "External" { 
                background #999999 
                color #ffffff 
            }
            element "Database" { 
                shape Cylinder 
                background #1262F7 
            }
            element "Broker" { 
                shape Pipe 
                background #85bbf0 
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}