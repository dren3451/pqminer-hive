# pqminer-open: отдельный полётник CMP 90HX

Публичные архивы содержат только Hive-скрипты. Бинарники хранятся в приватном `dren3451/pqminer` и скачиваются с GitHub-токеном. Здесь нет токена или бинарника.

## Текущая установка: 0.1.7-open3

| Поле | Значение |
| --- | --- |
| Miner name | `pqminer-open` |
| Installation URL | https://raw.githubusercontent.com/dren3451/pqminer-hive/pqminer-open/codex/pqminer-open-loader2.tar.gz |
| Wallet template | `%WAL%.%WORKER_NAME%` |
| Pool URL | Ваш обычный Pearl pool URL |
| Password | `x` или ваш пароль пула |
| Extra config arguments | `-a pearl --gh-token github_pat_... --pearl-kernel legacy` |

Токен: **Contents: Read-only** для приватного `dren3451/pqminer`. Настоящий токен указывается только в полётнике или в `/hive-config/pqminer.token` на риге. Загрузчик удаляет его перед записью конфигурации майнера. Прежний токен подходит, если у него уже есть нужный доступ.

По умолчанию в loader2 выбран **legacy**. Результат пользователя для прежнего бинарника open1: около **28 TH/s** на open и **42.1 TH/s** на legacy, плюс принятая пулом шара на legacy. Регрессия open1 подтверждена. Разрыв с SRBMiner пока не устранён.

Open3 меняет загрузки в ядре: последовательные восемь потоков на строку, ldmatrix вместо отдельных чтений фрагментов, одна синхронизация CTA в цикле. Для проверки добавьте `--pearl-kernel open` вместо `--pearl-kernel legacy`. Стартап проверяет 3072 хеша по CPU-эталону; при ошибке GPU не начинает майнинг. Скорость open3 ещё не измерена на GPU.

Приватная ветка: `codex/pearl-open-kernel`.
Исходники: `a89b2313c0d8c6e8bd88cfeb8c91bcd241628e91`.
Коммит с бинарником: `7e08c4c49a7560b6ae3d8b96aa4a45475346c243`.
SHA-256 приватного архива: `cde52ab28a8e4662dc8aa6ab61288d6f786f7f16feefca6725a33ac4d2e791fa`.
SHA-256 бинарника: `f341a9c1be52f73abcc9cfbbb8dd9ef1f920f3faa36b9d0b955bc7663c9f39ee`.
Загрузчик закреплён за коммитом и проверяет оба SHA-256, не следует latest/main.

Папка: `/hive/miners/custom/pqminer-open`; логи: `/var/log/miner/pqminer-open/`; API: `44069`. Другой custom miner `pqminer` не изменяется.

Loader1 оставлен для воспроизводимости: он скачивает прежнюю open1 и по умолчанию выбирает open. Loader2 скачивает open3 и по умолчанию выбирает legacy. Проверки CPU, загрузчика и компиляция CUDA пройдены; GPU-тест open3 и его принятые шары ещё нужны.
