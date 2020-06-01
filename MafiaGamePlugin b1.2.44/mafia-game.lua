obs           = obslua
bit = require("bit")
ElemCurrent = 0;
CountCard = 11;
RandNum = {}

source_name = 'MafiaCards'
data = {}

img_size_w = 0
img_size_h = 0

hotkey_id     = obs.OBS_INVALID_HOTKEY_ID

source_def = {}
source_def.id = "mafia_cards_source"
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO, obs.OBS_SOURCE_CUSTOM_DRAW)


math.randomseed(os.time());

--Задает массив указаного размера
function getRandomCard(CountCard)
	for i = 1, CountCard do
		table.insert(RandNum, i)
	end
	shuffle(RandNum)
	for i = 1, #RandNum do
		print(RandNum[i])
	end
end

--Функция Shuffle рандомно переставляет значения в указанном массиве 
function shuffle(array)
	local currentIndex = #array + 1;
	local temporaryValue;
	local randomIndex;

	while (currentIndex > 1) do
		
		randomIndex = math.ceil(math.random() * currentIndex);
		currentIndex = currentIndex - 1;
		
		temporaryValue = array[currentIndex];
		array[currentIndex] = array[randomIndex];
		array[randomIndex] = temporaryValue;
	end
	
	return array;
end


-- Функция для загрузки изображений
function image_source_load(image, file)
	obs.obs_enter_graphics();
	obs.gs_image_file_free(image);
	obs.obs_leave_graphics();
	
	obs.gs_image_file_init(image, file);
	
	obs.obs_enter_graphics();
	obs.gs_image_file_init_texture(image);
	obs.obs_leave_graphics();
	
	if not image.loaded then
		print("Ошибка загрузки изображения " .. file);
	end
end

-- установка имени источника
source_def.get_name = function()
	return "MafiaCards"
end

-- при создании источника задает изображение
source_def.create = function(source, settings)
	data.image = obs.gs_image_file()
	image_source_load(data.image, script_path() .. "mafia-cards/card_main.png")
	return data
end

-- при уничтожении освобождает данные
source_def.destroy = function(data)
	obs.obs_enter_graphics();

	obs.gs_image_file_free(data.image);

	obs.obs_leave_graphics();
end

-- рисует текстуру изображения
source_def.video_render = function(data, effect)
	if not data.image.texture then
		return;
	end

	effect = obs.obs_get_base_effect(obs.OBS_EFFECT_DEFAULT)
	
	img_size_w = obs.gs_texture_get_width(data.image.texture)
	img_size_h = obs.gs_texture_get_height(data.image.texture)

	obs.gs_blend_state_push()
	obs.gs_reset_blend_state()
	while obs.gs_effect_loop(effect, "Draw") do
		obs.obs_source_draw(data.image.texture, 0, 0, data.image.cx, data.image.cy, false);
	end

	obs.gs_matrix_pop()

	obs.gs_blend_state_pop()
end

-- ширина источника
source_def.get_width = function(data)
	return img_size_w
end

-- высота источника
source_def.get_height = function(data)
	return img_size_h
end

source_def.activate = function(data)
	-- if ElemCurrent ~= 0 then
	-- 	set_image()
	-- end
	image_source_load(data.image, script_path() .. "mafia-cards/card_main.png")
	obs.timer_add(timer_callback, 650)
end

source_def.deactivate = function(data)
	obs.timer_remove(timer_callback)
end

-- задает изображения по индексу
function set_image()
	local text;
	print(ElemCurrent)
	text = RandNum[ElemCurrent];
	if (ElemCurrent > #RandNum) then
		ElemCurrent = 0
	end
	if ElemCurrent == 0 then
		RandNum = {}
		image_source_load(data.image, script_path() .. "mafia-cards/card_main.png")
	else
		image_source_load(data.image, script_path() .. "mafia-cards/" .. tostring(text) .. ".png")
	end

end

function timer_callback()
	ElemCurrent = ElemCurrent + 1

	obs.remove_current_callback()
	set_image()
end


-- функция на кнопку перемешивания карт
function reset(pressed)
	if not pressed then
		return
	end

	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		RandNum = {}
		ElemCurrent = 0
		getRandomCard(CountCard)
		obs.timer_add(imgload, 100)

		obs.obs_source_release(source)
	end
end

-- фунция загрузки изображения для кнопки
function imgload()
	image_source_load(data.image, script_path() .. "mafia-cards/card_main.png")
	obs.remove_current_callback(imgload)
end


-- функция на кнопку ресета
function reset_button_clicked(props, p)
	local source = obs.obs_get_source_by_name(source_name)
	local active = obs.obs_source_active(source)

	if active == true then
		reset(true)
		obs.obs_source_release(source)
		return false
	else
		obs.obs_source_release(source)
		return print("Сделайте источник карт видимым")
	end

end


----------------------------------------------------------

-- настройки, которые будут отображены для пользователя
function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int_slider(props, "cardcount", "Количество карт", 1, 20, 1)
	

	obs.obs_properties_add_button(props, "reset_button", "Перемешать карты", reset_button_clicked)
	return props
end

-- Описание для пользователя
function script_description()
	return "Добавьте источник \"MafiaCards\", для работы плагина.\n\nСделал Приваленков Кирилл"
end

-- функция, которая вызывается после изменения настроек
function script_update(settings)
	CountCard = obs.obs_data_get_int(settings, "cardcount")
end

-- стандартные настройки
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "cardcount", 11)
end

-- функция вызывается, когда скрипт сохраняется
function script_save(settings)
	local hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
	obs.obs_data_set_array(settings, "reset_hotkey", hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- функция вызывается при загрузке скрипта
function script_load(settings)
	hotkey_id = obs.obs_hotkey_register_frontend("reset_timer_thingy", "Перемешать карты", reset)
	local hotkey_save_array = obs.obs_data_get_array(settings, "reset_hotkey")
	obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
	obs.obs_data_array_release(hotkey_save_array)
end

-- регистрирует источник, для отображения его в списке источников
obs.obs_register_source(source_def)