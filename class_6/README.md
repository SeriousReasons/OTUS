# Управление пакетами. Дистрибьюция софта

- я добавил в spec nginx модуль google_perftools_module и в конфигурации заменнил дефолтное значение worker_processes. В Vagrantfile все автоматизировано.

- Из-за особенености обработки Vagrant команды "sed" пришлось вынести команды в отдельный файл.

- Пакет имеет дупдикат по имени, поэтому его необходимо искать следующей командой  
`yum list --showduplicates | grep vagrant`
