// Функция для конвертации HTML в PDF
async function convertToPdf(htmlContent) {
    try {
        // Собираем все переменные в объект
        const variables = {};
        document.querySelectorAll('#variables-container .variable-group').forEach(group => {
            const nameInput = group.querySelector('input[name$="[name]"]');
            const typeSelect = group.querySelector('select[name$="[type]"]');
            const valueInput = group.querySelector('[name$="[value]"]');
            
            if (nameInput?.value && valueInput) {
                let value = valueInput.value;
                
                // Преобразуем значение в зависимости от типа
                switch(typeSelect.value) {
                    case 'boolean':
                        value = value === 'true';
                        break;
                    case 'array':
                        value = value.split('\n')
                            .map(item => item.trim())
                            .filter(item => item.length > 0);
                        break;
                }
                
                variables[nameInput.value] = value;
            }
        });

        const response = await fetch('/convert', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: new URLSearchParams({
                html_content: htmlContent || document.getElementById('html_content').value,
                page_size: document.getElementById('page_size').value,
                margin_top: document.getElementById('margin_top').value,
                margin_right: document.getElementById('margin_right').value,
                margin_bottom: document.getElementById('margin_bottom').value,
                margin_left: document.getElementById('margin_left').value,
                variables: JSON.stringify(variables)
            })
        });
        
        const result = await response.json();
        
        if (result.success) {
            // Показываем PDF в превью
            const previewContainer = document.getElementById('preview-container');
            previewContainer.innerHTML = `<iframe id="pdf-preview" src="${result.pdf_url}"></iframe>`;
        } else {
            alert('Ошибка при конвертации в PDF: ' + result.error);
        }
    } catch (error) {
        alert('Ошибка при конвертации в PDF: ' + error.message);
    }
}

// Счетчик для уникальных идентификаторов переменных
let variableCounter = 0;

// Функция для добавления новой переменной
function addVariable() {
    const container = document.getElementById('variables-container');
    const group = document.createElement('div');
    group.className = 'variable-group';
    
    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.name = `variables[${variableCounter}][name]`;
    nameInput.placeholder = 'Имя переменной';
    
    const typeSelect = document.createElement('select');
    typeSelect.name = `variables[${variableCounter}][type]`;
    
    const types = [
        { value: 'string', label: 'Текст' },
        { value: 'boolean', label: 'Да/Нет' },
        { value: 'array', label: 'Массив' }
    ];
    
    types.forEach(type => {
        const option = document.createElement('option');
        option.value = type.value;
        option.textContent = type.label;
        typeSelect.appendChild(option);
    });
    
    const valueContainer = document.createElement('div');
    
    function updateValueInput() {
        const type = typeSelect.value;
        valueContainer.innerHTML = '';
        
        switch(type) {
            case 'string':
                const textInput = document.createElement('input');
                textInput.type = 'text';
                textInput.name = `variables[${variableCounter}][value]`;
                textInput.placeholder = 'Значение';
                valueContainer.appendChild(textInput);
                break;
                
            case 'boolean':
                const boolSelect = document.createElement('select');
                boolSelect.name = `variables[${variableCounter}][value]`;
                
                ['true', 'false'].forEach(value => {
                    const option = document.createElement('option');
                    option.value = value;
                    option.textContent = value === 'true' ? 'Да' : 'Нет';
                    boolSelect.appendChild(option);
                });
                
                valueContainer.appendChild(boolSelect);
                break;
                
            case 'array':
                const arrayInput = document.createElement('textarea');
                arrayInput.name = `variables[${variableCounter}][value]`;
                arrayInput.placeholder = 'Введите элементы массива, по одному на строку';
                arrayInput.style.minHeight = '60px';
                valueContainer.appendChild(arrayInput);
                break;
        }

        // Добавляем слушатель для автоматической конвертации при изменении значения
        const valueInput = valueContainer.firstChild;
        if (valueInput) {
            valueInput.addEventListener('change', debounceConvert);
            valueInput.addEventListener('input', debounceConvert);
        }
    }
    
    typeSelect.addEventListener('change', () => {
        updateValueInput();
        debounceConvert();
    });
    
    const deleteButton = document.createElement('button');
    deleteButton.type = 'button';
    deleteButton.textContent = 'Удалить';
    deleteButton.className = 'delete-button';
    deleteButton.onclick = () => {
        container.removeChild(group);
        debounceConvert();
    };
    
    group.appendChild(nameInput);
    group.appendChild(typeSelect);
    group.appendChild(valueContainer);
    group.appendChild(deleteButton);
    
    container.appendChild(group);
    updateValueInput();
    
    // Добавляем слушатели для автоматической конвертации
    nameInput.addEventListener('input', debounceConvert);
    
    variableCounter++;
}

// Добавляем таймер для отложенной конвертации
let convertTimeout;
function debounceConvert() {
    clearTimeout(convertTimeout);
    convertTimeout = setTimeout(() => {
        convertToPdf();
    }, 1000); // Задержка в 1 секунду
}

// Добавляем слушатель изменений в textarea
document.getElementById('html_content').addEventListener('input', debounceConvert);

// Добавляем слушатели для остальных полей формы
['page_size', 'margin_top', 'margin_right', 'margin_bottom', 'margin_left'].forEach(id => {
    const element = document.getElementById(id);
    if (element) {
        element.addEventListener('change', debounceConvert);
    }
});

// Функция для загрузки примера HTML
function loadExample() {
    const exampleHtml = `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Пример документа</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #2c3e50; }
        .content { margin-top: 20px; }
        {{#watermark}}
        .watermark::after {
            content: "ОБРАЗЕЦ";
            position: absolute;
            bottom: 50%;
            left: 10%;
            transform: translate(-50%, 50%) rotate(315deg);
            font-size: 140px;
            color: rgba(0, 0, 0, 0.25);
            z-index: -1;
            white-space: nowrap;
            font-family: Arial, sans-serif;
        }
        {{/watermark}}
    </style>
</head>
<body>
    <div class="watermark">
        <h1>Пример документа</h1>
        <div class="content">
            <p>Это пример HTML документа для конвертации в PDF.</p>
            <p>Чтобы включить/выключить водяной знак, используйте переменную типа "Да/Нет" с именем "watermark".</p>
        </div>
    </div>
</body>
</html>`;
    document.getElementById('html_content').value = exampleHtml;
    
    // Добавляем переменную watermark
    addVariable();
    const group = document.querySelector('#variables-container .variable-group:last-child');
    const nameInput = group.querySelector('input[name$="[name]"]');
    const typeSelect = group.querySelector('select[name$="[type]"]');
    
    nameInput.value = 'watermark';
    typeSelect.value = 'boolean';
    typeSelect.dispatchEvent(new Event('change')); // Обновляем поле значения
    
    // После обновления поля значения ищем новый select
    const newValueSelect = group.querySelector('select[name$="[value]"]');
    if (newValueSelect) newValueSelect.value = 'true';
    
    convertToPdf(exampleHtml);
} 