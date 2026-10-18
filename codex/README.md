# pqminer-open: отдельный полётник для эксперимента CMP 90HX

Публичный архив содержит только четыре Hive-скрипта. Сам майнер хранится в приватном `dren3451/pqminer` и скачивается только с GitHub-токеном. Токен в этом репозитории отсутствует.

## Настройки Custom miner

| Поле | Значение |
| --- | --- |
| Miner name | `pqminer-open` |
| Installation URL | https://raw.githubusercontent.com/dren3451/pqminer-hive/pqminer-open/codex/pqminer-open-loader1.tar.gz |
| Wallet template | `%WAL%.%WORKER_NAME%` |
| Pool URL | Ваш обычный Pearl pool URL |
| Password | `x` или ваш пароль пула |
| Extra config arguments | `-a pearl --gh-token github_pat_...` |

Токен: доступ **Contents: Read-only** только к приватному `dren3451/pqminer`. Укажите настоящий токен только в своём полётнике или в файле `/hive-config/pqminer.token` на риге. Загрузчик удаляет `--gh-token` из конфигурации, передаваемой майнеру.

Версия `0.1.7-open1`. Приватная ветка: `codex/pearl-open-kernel`.
Исходники: `bc3e0bbed7ed00fbf2f87dd1d1c0175b8bb56709`.
Коммит с бинарником: `7189576c09b83e2513449c4153039293308340e5`.
Загрузчик закреплён за этим коммитом, проверяет SHA-256 архива и бинарника и не следует за latest/main.

Установка: `/hive/miners/custom/pqminer-open`, логи: `/var/log/miner/pqminer-open/`, локальный API: `44069`.

По умолчанию выбирается экспериментальное ядро `open`. Для сравнения добавьте `--pearl-kernel legacy` в Extra config arguments. Оба ядра находятся в одном приватном бинарнике. Перед майнингом open выполняет 3072 проверки тайлов по CPU-эталону. При несовпадении GPU не начинает майнинг.

Компиляция и CPU-проверки пройдены; GPU-проверки и прирост хешрейта здесь не измерены. Сравнивайте на одном GPU при одинаковых частотах и лимите мощности, затем проверяйте принятые пулом шары.

SHA-256 публичного загрузчика: `ed08ac8e427eb6d4e2d2d6f36dcc356b96e994a4289575250e3931bfeccb6ae5`.
