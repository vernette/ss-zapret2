![Zapret2 Version](https://img.shields.io/badge/zapret2-v0.8.1-red)
![Docker Pulls](https://img.shields.io/docker/pulls/vernette/ss-zapret2?logo=docker)

Docker-контейнер на основе [zapret2 от bol-van](https://github.com/bol-van/zapret2) с интегрированным Shadowsocks и SOCKS5 для подключения к контейнеру. Предназначен для удобной маршрутизации трафика через изолированную среду без модификации основной сети. Продолжение [ss-zapret](https://github.com/vernette/ss-zapret).

- Изоляция zapret2 в отдельном контейнере
- Простая интеграция с sing-box, Xray и другими прокси-клиентами

Контейнер был протестирован на следующих хостингах:

- [RocketCloud](https://cloudcore.ru/?affiliate_uuid=ce1874ee-4940-48b1-b37d-60e03cfada66)
- [HSVDS](https://hsvds.ru/signup/?refid=20241026-9939487-843)
- [VDS Selectel MSK](https://vds.selectel.ru)
- [Aeza MSK](https://aeza.net/?ref=463603)
- [VDC MSK](https://my.vdc.ru/?affid=191) - промокод `VERNETTE` на скидку в 9%
- [RUVDS MSK](https://ruvds.com)
- [4VPS](https://4vps.su/r/v4LLSnpUc6Yv) - проверялся сервер в Кемерово. Скидка 20% на первый заказ

> [!CAUTION]
> В режиме `nfqws` контейнер работает только на Linux из-за отсутствия `nfqueue` на других ОС

## Содержание

- [Быстрый старт](#быстрый-старт)
  - [Предварительные требования](#предварительные-требования)
  - [Установка и запуск](#установка-и-запуск)
- [Изменение конфигурации](#изменение-конфигурации)
- [Расширенные возможности](#расширенные-возможности)
  - [Поиск стратегий](#поиск-стратегий)
  - [Custom.d скрипты](#customd-скрипты)
  - [Lua](#lua)
  - [Проверка работы стратегий](#проверка-работы-стратегий)
  - [Интеграция с прокси-клиентами](#интеграция-с-прокси-клиентами)
- [Работа Instagram в браузере](#работа-instagram-в-браузере)
- [Предупреждение про Shadowsocks и SOCKS5](#предупреждение-про-shadowsocks-и-socks5)

## Быстрый старт

### Предварительные требования

1. Установка git:

```bash
# Ubuntu/Debian
sudo apt install git

# Fedora
sudo dnf install git

# Arch Linux
sudo pacman -S git
```

2. Установка Docker:

```bash
bash <(wget -qO- https://get.docker.com)
```

### Установка и запуск

1. Клонируйте репозиторий:

```bash
git clone https://github.com/vernette/ss-zapret2
cd ss-zapret2
```

2. Скопируйте стандартный конфиг zapret2:

```bash
cp config.default config
```

3. Cоздайте `.env` файл. За основу можно взять `.env.example`:

```bash
cp .env.example .env
nano .env
```

Пример содержимого `.env`:

```env
SS_PORT=8388                                # Порт Shadowsocks
SOCKS_PORT=1080                             # Порт SOCKS5
SS_PASSWORD=SuperSecurePassword             # Пароль (рекомендуется изменить!)
SS_ENCRYPT_METHOD=chacha20-ietf-poly1305    # Метод шифрования
SS_TIMEOUT=300                              # Таймаут подключения
```

> [!NOTE]
> Необязательно использовать `.env` файл. Вы можете задать переменные окружения вручную прямо в `docker-compose.yml`

Список переменных окружения в `docker-compose.yml`:

| Переменная                                  | Описание                                                                                               |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| SS_PORT: `8388`                             | Порт Shadowsocks                                                                                       |
| SOCKS_PORT: `1080`                          | Порт SOCKS5                                                                                            |
| SS_PASSWORD: `SuperSecurePassword`          | Пароль для Shadowsocks                                                                                 |
| SS_ENCRYPT_METHOD: `chacha20-ietf-poly1305` | Метод шифрования Shadowsocks                                                                           |
| SS_TIMEOUT: `300`                           | Таймаут сокета Shadowsocks в секундах                                                                  |
| SS_VERBOSE: `0`, `1`                        | Логгирование Shadowsocks. Если переменная не установлена или равна `1`, то по-умолчанию будет включено |

4. Запустите контейнер:

```bash
docker compose up -d
```

## Изменение конфигурации

Для внесения изменений в конфиг открываем его в текстовом редакторе:

```bash
nano config
```

Стратегия меняется в переменной `NFQWS2_OPT`, например:

```
NFQWS2_OPT="
--filter-tcp=80 --filter-l7=http --payload http_req --lua-desync=http_methodeol --new
--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --hostlist-domains=youtube.com,googlevideo.com,youtubei.googleapis.com --lua-desync=multisplit:pos=10:seqovl=1 --new
--filter-tcp=443 --filter-l7=tls --payload=tls_client_hello --lua-desync=multidisorder:pos=2 --new
--filter-udp=443 --filter-l7=quic --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6
"
```

- `--filter-tcp=80` - стратегия для всего HTTP трафика
- `--filter-tcp=443 ... --hostlist-domains=youtube.com,googlevideo.com,youtubei.googleapis.com` - стратегия для HTTPS для определенных доменов
- `--filter-tcp=443` - стратегия для всего остального HTTPS трафика
- `--filter-udp=443` - стратегия для всего HTTP3 (QUIC) трафика

После внесения изменений не забудьте перезапустить контейнер:

```bash
docker compose restart
```

## Расширенные возможности

### Поиск стратегий

Перед поиском стратегий нужно обязательно остановить zapret2 командой, чтобы поиск шёл без модификации трафика:

```bash
docker compose exec ss-zapret2 sh /opt/zapret2/init.d/sysv/zapret2 stop
```

Как и в оригинальном проекте, поиск стратегий осуществляется скриптом `blockcheck2.sh`. Этот скрипт подбирает оптимальные стратегии для вашего домашнего/хостинг провайдера:

```bash
docker compose exec ss-zapret2 sh /opt/zapret2/blockcheck2.sh
```

> [!TIP]
> К скрипту поиска можно применять дополнительные параметры. Например, вам скорее всего не нужен режим TPWS и мы можем отключить поиск стратегий для него, чем сократим время поиска. Более подробно в [оригинальном репозитории](https://github.com/bol-van/zapret?tab=readme-ov-file#%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D1%80%D0%BE%D0%B2%D0%B0%D0%B9%D0%B4%D0%B5%D1%80%D0%B0)

Пример запуска с параметрами:

```bash
docker compose exec ss-zapret2 sh -c 'SKIP_TPWS=1 REPEATS=8 DOMAINS="amnezia.org discord.com" /opt/zapret2/blockcheck2.sh'
```

#### Поиск стратегий для HTTP, HTTPS TLS 1.2, без HTTPS TLS 1.3 и HTTP3 (QUIC). Подходит для сайтов, которые не поддерживают TLS 1.3 (таких мало, но они есть)

```bash
docker compose exec ss-zapret2 sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=1 ENABLE_HTTPS_TLS12=1 ENABLE_HTTPS_TLS13=0 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="amnezia.org discord.com" /opt/zapret2/blockcheck2.sh'
```

#### Поиск стратегий для HTTPS TLS 1.3, без HTTP, HTTPS TLS 1.2 и HTTP3 (QUIC). Подходит для большинства сайтов и серверов YouTube

```bash
docker compose exec ss-zapret2 sh -c 'SKIP_TPWS=1 SKIP_DNSCHECK=1 SECURE_DNS=0 IPVS=4 ENABLE_HTTP=0 ENABLE_HTTPS_TLS12=0 ENABLE_HTTPS_TLS13=1 ENABLE_HTTP3=0 REPEATS=8 PARALLEL=1 SCANLEVEL=standard BATCH=1 DOMAINS="xxxxxx.googlevideo.com" /opt/zapret2/blockcheck2.sh'
```

После завершения поиска стратегий запустите zapret2 командой:

```bash
docker compose exec ss-zapret2 sh /opt/zapret2/init.d/sysv/zapret2 start`
```

Либо перезапустите контейнер:

```bash
docker compose restart
```

### Custom.d скрипты

После первого запуска контейнера в директории проекта будет создана директория `scripts`:

```
scripts
├── custom.d
└── examples
    ├── 10-keenetic-udp-fix
    ├── 20-fw-extra
    ├── 40-webserver
    ├── 50-dht4all
    ├── 50-discord-media
    ├── 50-nfqws-ipset
    ├── 50-quic4all
    ├── 50-stun4all
    └── 50-wg4all
```

Для того, чтобы использовать эти скрипты, необходимо скопировать их из директории `examples` в директорию `custom.d`. Например, скопируем скрипты для Discord и Stun (Telegram, WhatsApp):

```bash
cp scripts/examples/{50-discord-media,50-stun4all} scripts/custom.d
```

После чего необходимо перезапустить контейнер, чтобы скрипты применились:

```bash
docker compose restart
```

### Lua

После первого запуска контейнера в директории проекта будет создана директория `lua`:

```
lua/
├── zapret-antidpi.lua
├── zapret-auto.lua
├── zapret-lib.lua
├── zapret-pcap.lua
├── zapret-tests.lua
└── zapret-wgobfs.lua
```

Помимо стандартных скриптов, вы можете добавлять собственные lua-файлы для расширения функциональности.

### Проверка работы стратегий

Проверить работу стратегий можно используя скрипт [censorcheck](https://github.com/vernette/censorcheck), указав локальный прокси контейнера:

```bash
bash <(wget -qO- https://github.com/vernette/censorcheck/raw/master/censorcheck.sh) --mode dpi --proxy localhost:1080
```

Проверить работу видео-доменов YouTube можно следующей командой:

```bash
curl --connect-to ::speedtest.selectel.ru https://manifest.googlevideo.com/100MB -k -o/dev/null -x socks5://localhost:1080
```

В поле `Current speed` должна расти скорость скачивания. Если она вообще не идёт или постоянно прыгает (во втором случае всё равно нужно проверить работу видео вручную) - стратегия не подходит.

### Интеграция с прокси-клиентами

Интеграция ничем не отличается от [ss-zapret](https://github.com/vernette/ss-zapret).

Примеры интеграции с sing-box, Xray и в существующий проект: [INTEGRATION.md](https://github.com/vernette/ss-zapret/blob/master/INTEGRATION.md)

## Работа Instagram в браузере

> [!WARNING]
> Этот пункт выполняется на **удалённом сервере**. Если контейнер работает в локальной сети, то прописывайте IP на роутере или шлюзе

> [!WARNING]
> Не всегда на клиентах сразу заработает Instagram в браузере, возможно придётся поиграться с DNS

Чаще всего IP Instagram будет заблокирован и будет работать только в мобильном приложении.

Чтобы решить эту проблему, нам нужно найти незаблокированный IP и прописать его в `docker-compose.yml` на сервере:

```yaml
ss-zapret2:
  image: vernette/ss-zapret2:v0.8.1
  container_name: zapret2-proxy
  restart: unless-stopped
  ...
  healthcheck:
    test: [
      "CMD-SHELL",
      "nc -z localhost ${SS_PORT} && nc -z localhost ${SOCKS_PORT} || exit 1"
    ]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 3s
  extra_hosts:
    instagram.com: "незаблокированный_ip"
    www.instagram.com: "незаблокированный_ip"
  cap_add:
    - NET_ADMIN
```

> Например instagram.com: "11.22.33.44"

После чего перезапустить compose, чтобы он прописал изменения в файл `/etc/hosts` контейнера:

```bash
docker compose down && docker compose up -d
```

## Сценарии использования

- **Локальное использование**: Запуск контейнера на домашнем сервере для изолированной работы zapret2 без модификации основной сети
- **Серверное использование**: Развертывание на удалённом VPS как единая точка подключения

## Разработка

Сборка образа с другой версией zapret2:

```bash
docker build -t ss-zapret2:v0.8 --build-arg ZAPRET_TAG=v0.8 .
```

Затем отредактируйте `docker-compose.yml`:

```yaml
ss-zapret2:
  image: ss-zapret2:v0.8
```

## Вклад в разработку

Если у вас есть идеи для улучшения проекта, вы нашли баг или хотите предложить новую функциональность - не стесняйтесь создавать [issue](https://github.com/vernette/ss-zapret2/issues) или отправлять [pull request](https://github.com/vernette/ss-zapret2/pulls).

## Предупреждение про Shadowsocks и SOCKS5

> [!IMPORTANT]
> Shadowsocks и SOCKS5 предназначены только для подключения в **локальной** сети. Не рекомендуется использовать их для внешнего подключения, так как это может скомпрометировать сервер
