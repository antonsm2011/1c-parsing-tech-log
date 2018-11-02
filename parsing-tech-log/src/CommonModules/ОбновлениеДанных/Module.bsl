#Область ЧтениеЖурнала

Функция ПолучитьСтруктуруЗаписиЖурнала() Экспорт
	//структура записи журнала
	СтруктураЗаписи = Новый Структура;
	СтруктураЗаписи.Вставить("Замер");
	СтруктураЗаписи.Вставить("Процесс");
	СтруктураЗаписи.Вставить("ПроцессID");
	СтруктураЗаписи.Вставить("ПериодФайла");
	СтруктураЗаписи.Вставить("ПериодСобытия"); //параметры события
	СтруктураЗаписи.Вставить("ДоляПериода");
	СтруктураЗаписи.Вставить("Событие");
	СтруктураЗаписи.Вставить("КлючСобытия");
	СтруктураЗаписи.Вставить("Длительность");
	СтруктураЗаписи.Вставить("Уровень");
	СтруктураЗаписи.Вставить("ЗначениеСвойств");
	СтруктураЗаписи.Вставить("Свойства", Новый Соответствие);
	Возврат СтруктураЗаписи;
КонецФункции

Функция РазобратьФайл(Процесс, ПроцессID, Период, ИмяФайлаДляРазбора,Замер=Неопределено) Экспорт
	//РазмерФайла = Данные.Размер();
	
	//еще раз проверим прочитан полностью
	СостояниеЧтения = РегистрыСведений.ГраницыЧтенияДанных.ПолучитьСостояние(Замер, Процесс, ПроцессID, Период);
	Если СостояниеЧтения.ПрочитанПолностью Тогда
		Возврат 0;
	КонецЕсли;		
	
	//пропуск пустых файлов
	ФайлТЖ = Новый Файл(ИмяФайлаДляРазбора);
	РазмерФайла = ФайлТЖ.Размер();
	Если РазмерФайла <=3 Тогда
		Возврат 0;
	КонецЕсли;
	
	ДатаНачалаЧтения = ТекущаяДата();
	
	Текст = Новый ЧтениеТекста(ИмяФайлаДляРазбора, КодировкаТекста.UTF8, Символы.ВК + Символы.ПС, "", Ложь);
	
	ПозиционироватьЧтениеНаСтрокуФайла(Текст, СостояниеЧтения.ПрочитаноСтрок);

	//продолжаем чтение с позиции СостояниеЧтения.ПрочитаноСтрок
	ПрочитаноСтрок = СостояниеЧтения.ПрочитаноСтрок;
	СтрокаТекста = Текст.ПрочитатьСтроку();
	Если СтрокаТекста = Неопределено Тогда
		
		//может быть прочитано строк не поменялось а полностью поменялось 
		РегистрыСведений.ГраницыЧтенияДанных.УстановитьСостояние(
			Замер, 
			Процесс, 
			ПроцессID, 
			Период, 
			ПрочитаноСтрок, 
			ДатаНачалаЧтения, 
			РазмерФайла);
		
		Возврат 0;
	КонецЕсли;
	ПрочитаноСтрок = ПрочитаноСтрок + 1;
	
	//регэксп объекты
	Анализатор = Новый COMОбъект("VBScript.RegExp");
	Анализатор.Global = Истина;
	Анализатор.Pattern = "([0-9]{2}):([0-9]{2})\.([0-9]+)\-([0-9]+)\,(\w+)\,(\d+)";
	АнализаторСвойств = Новый COMОбъект("VBScript.RegExp");
	АнализаторСвойств.Global = Истина;
	//#7
	//АнализаторСвойств.Pattern = ",([^,=]+)=('[\s\S]+'|""[\s\S]+""|[^,]+)";
	АнализаторСвойств.Pattern = ",([^""',=]+)=('[^']+'|""[^""]+""|[^""',]+)";
	
	АнализаторДвойныеКавычкиВДвойныхКавычках = 	Новый COMОбъект("VBScript.RegExp");
	АнализаторДвойныеКавычкиВДвойныхКавычках.Global = Истина;
	АнализаторДвойныеКавычкиВДвойныхКавычках.Pattern = ",([^""',=]+)=""[^""]*""{2}[^""]*""";
	ЗаменительДвойныхКавычек = "ЁЁ";	
	
	ПроцессСсылка = СправочникиСерверПовтИсп.ПолучитьПроцесс(Процесс);
	
	//часть реквизитов будет одинакова для всего файла
	СтруктураЗаписи = ПолучитьСтруктуруЗаписиЖурнала();
	СтруктураЗаписи.Замер = Замер;
	СтруктураЗаписи.Процесс = ПроцессСсылка;
	СтруктураЗаписи.ПроцессID =  ПроцессID;
	СтруктураЗаписи.ПериодФайла = Период;
	
	//БылаЗаписьНабора = Ложь;
//	ПрочитаноРазмер = 0;
	//СтруктураСостояния = Новый Структура("Прочитано");
	РазобраноСтрок = 0;
	
	Пока СтрокаТекста <> Неопределено Цикл
		
//		ПрочитаноРазмер = ПрочитаноРазмер + СтрДлина(СтрокаТекста);
		
		// Проверяем, является ли следующая строка начальной строкой журнала
		СледующаяСтрока = Текст.ПрочитатьСтроку();
		
		Если СледующаяСтрока <> Неопределено Тогда
			ПрочитаноСтрок = ПрочитаноСтрок + 1;
			
			Совпадения = Анализатор.Execute(СледующаяСтрока);
			Если Совпадения.Count() = 0 Тогда
				// если следующая строка не соответствует шаблону - добавляем ее к текущей строке и пытаемся распознать объединенную часть
				СтрокаТекста = СтрокаТекста + Символы.ПС + СледующаяСтрока; //#11 сохраняем переносы строк
				Продолжить;
			КонецЕсли;
		КонецЕсли;
		
		Совпадения = Анализатор.Execute(СтрокаТекста);
		Если Совпадения.Count() = 1 Тогда
			Совпадение = Совпадения.Item(0);
			Минуты = Число(Совпадение.SubMatches.Item(0));
			Секунды = Число(Совпадение.SubMatches.Item(1));
			ДолиСекунды = Число(Совпадение.SubMatches.Item(2));
			Длительность = Число(Совпадение.SubMatches.Item(3));
			ИмяСобытия = Совпадение.SubMatches.Item(4);
			УровеньСобытия = Совпадение.SubMatches.Item(5);
		Иначе
			ВызватьИсключение "Нет соответствия шаблону! " + СтрокаТекста;
		КонецЕсли;
		КлючСобытия = Новый УникальныйИдентификатор;
		
		СтруктураЗаписи.Событие =СправочникиСерверПовтИсп.ПолучитьСобытие(ИмяСобытия);
		СтруктураЗаписи.ПериодСобытия = Период + Секунды + (Минуты * 60);
		СтруктураЗаписи.ДоляПериода = Число(ДолиСекунды);
		СтруктураЗаписи.Уровень = Число(УровеньСобытия);
		СтруктураЗаписи.Длительность = Число(Длительность);
		СтруктураЗаписи.КлючСобытия = КлючСобытия;
		СтруктураЗаписи.Свойства.Очистить();

		ЗаменитьДвойныеКавычкиВДвойныхКавычках = АнализаторДвойныеКавычкиВДвойныхКавычках.Test(СтрокаТекста);
		Если ЗаменитьДвойныеКавычкиВДвойныхКавычках Тогда
			СтрокаТекста = СтрЗаменить(СтрокаТекста, """""", ЗаменительДвойныхКавычек);
		КонецЕсли;
		Совпадения = АнализаторСвойств.Execute(СтрокаТекста);
		Если Совпадения.Count() <> 0 Тогда
			
			// Масив имен свойств, необходим для устранения странного бага: иногда в ТЖ встречаются в одной строке два одинаковых свойства
			ТекстЗначениеСвойств = "";
			
			Для Сч = 0 По Совпадения.Count() - 1 Цикл
				Совпадение = Совпадения.Item(Сч);
				ИмяСвойства = Совпадение.SubMatches.Item(0);
				Свойство = СправочникиСерверПовтИсп.ПолучитьСвойство(ИмяСвойства);
				
				Если СтруктураЗаписи.Свойства.Получить(Свойство) = Неопределено Тогда 
				 
					ЗначениеСвойства = ЗначениеСвойстваБезЭкранирования(Совпадение.SubMatches.Item(1));
					Если ЗаменитьДвойныеКавычкиВДвойныхКавычках Тогда
						//обратно заменяем на ОДНУ двойную кавычку
						ЗначениеСвойства = СтрЗаменить(ЗначениеСвойства, ЗаменительДвойныхКавычек, """");
					КонецЕсли;

					СтруктураЗаписи.Свойства.Вставить(Свойство, ЗначениеСвойства);

					ТекстЗначениеСвойств = ТекстЗначениеСвойств + ИмяСвойства +" : "+ ЗначениеСвойства + Символы.ПС;
				КонецЕсли;
			КонецЦикла;
			СтруктураЗаписи.ЗначениеСвойств = ТекстЗначениеСвойств;
		КонецЕсли;
		
		РегистрыСведений.Журнал.ЗаписатьСобытие(СтруктураЗаписи);
		
		СтрокаТекста = СледующаяСтрока;
		РазобраноСтрок = РазобраноСтрок + 1;
	КонецЦикла;
	
	Текст.Закрыть();
	
	// Обновление инфорации о количестве прочитанных строк
	РегистрыСведений.ГраницыЧтенияДанных.УстановитьСостояние(
		Замер, 
		Процесс, 
		ПроцессID, 
		Период, 
		ПрочитаноСтрок, 
		ДатаНачалаЧтения,
		РазмерФайла);

	Возврат РазобраноСтрок;
КонецФункции

Процедура ПозиционироватьЧтениеНаСтрокуФайла(ЧтениеФайла, НомерСтроки)
	ТекНомерСтроки = 0;
	ТекСтрокаФайла = "";
	Пока ТекНомерСтроки < НомерСтроки 
		И ТекСтрокаФайла <> Неопределено Цикл
			ТекСтрокаФайла = ЧтениеФайла.ПрочитатьСтроку();
			ТекНомерСтроки = ТекНомерСтроки + 1;
	КонецЦикла; 
КонецПроцедуры

Функция ЗначениеСвойстваБезЭкранирования(ЗначениеСвойства)
	Результат = ЗначениеСвойства;
	Если Лев(ЗначениеСвойства,1)="'" И Прав(ЗначениеСвойства,1)="'" 
		ИЛИ Лев(ЗначениеСвойства,1)="""" И Прав(ЗначениеСвойства,1)="""" Тогда
			Результат = Сред(ЗначениеСвойства,2,СтрДлина(ЗначениеСвойства)-2);	
	КонецЕсли;
	Возврат СокрЛП(Результат);
КонецФункции

Функция ПолучитьВременныеПараметрыПоСвойствамФайла(Знач ФайлТЖ) Экспорт
	
	СвойстваФайла = новый Структура("Год,День,Месяц,Час,ДатаФайла");
	
	СвойстваФайла.Год = Число(Лев(ФайлТЖ.Имя, 2));
	СвойстваФайла.Месяц = Число(Сред(ФайлТЖ.Имя, 3, 2));
	СвойстваФайла.День = Число(Сред(ФайлТЖ.Имя, 5, 2));
	СвойстваФайла.Час = Число(Прав(ФайлТЖ.ИмяБезРасширения, 2));
	СвойстваФайла.ДатаФайла = Дата(СвойстваФайла.Год + 2000, СвойстваФайла.Месяц, СвойстваФайла.День, СвойстваФайла.Час, 0, 0);

	Возврат СвойстваФайла;
	
КонецФункции // ПрочитатьЖурналПоРегистру

#КонецОбласти

#Область ЧтениеИзОбработки

Процедура ЗагрузкаЖурнала(Замер=Неопределено,КаталогТЖ="",КлючФоновогоЗадания="") Экспорт
	//TODO: объединить с ЗагрузкаЖурналаПредварительноОчистить
	Если Замер=Неопределено Тогда
		ЗамерОбъект = Справочники.Замеры.СоздатьЭлемент();
		ЗамерОбъект.Наименование = "Новый Замер";
		ЗамерОбъект.ПолныйПуть = КаталогТЖ;
		ЗамерОбъект.Записать();
		Замер = ЗамерОбъект.Ссылка;
	КонецЕсли;
	
	ПрочитатьЖурнал(Замер,КаталогТЖ,КлючФоновогоЗадания);
КонецПроцедуры

Процедура ЗагрузкаЖурналаПредварительноОчистить(Замер=Неопределено,КаталогТЖ="", ЗагрузитьФоново=Ложь) Экспорт
	
	Если Замер=Неопределено Тогда
		ЗамерОбъект = Справочники.Замеры.СоздатьЭлемент();
		ЗамерОбъект.Наименование = "Новый Замер";
		ЗамерОбъект.ПолныйПуть = КаталогТЖ;
		ЗамерОбъект.Записать();
		Замер = ЗамерОбъект.Ссылка;
	Иначе
		ОчиститьЖурналы(Замер);
	КонецЕсли;
	
	//TODO: переренести проверку состояния загрузки из ПрочитатьЖурнал
	Если ЗагрузитьФоново Тогда
		Если Константы.МаксимальноеКолВоПотоковДляОднойЗагрузки.Получить()>1 Тогда
			ОбновлениеДанных.ЗагрузкаТЖПотоками(Замер,КаталогТЖ);
		Иначе
			ОбновлениеДанных.ПрочитатьЖурнал(Замер,КаталогТЖ);
		КонецЕсли;
	Иначе
		ПрочитатьЖурнал(Замер,КаталогТЖ);
	КонецЕсли;		
		
КонецПроцедуры

Процедура ПрочитатьЖурнал(Замер=Неопределено,КаталогТЖ="",КлючФоновогоЗадания="") Экспорт
	
	ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеНачато",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания);
	
	Если КаталогТЖ="" И НЕ ЗначениеЗаполнено(КлючФоновогоЗадания) Тогда
		ВызватьИсключение "Каталог ТЖ должен быть заполнен!";
	КонецЕсли;	
	Если НЕ ТипЗнч(КаталогТЖ)=Тип("Массив") Тогда
		ПапкиТЖ = НайтиФайлы(КаталогТЖ, "*");
	Иначе
		ПапкиТЖ = Новый Массив;
		ПапкиТЖ.Добавить(КаталогТЖ);
	КонецЕсли;
	Индекс = 0;
	
	//записать начало чтения. результат не проверяется (пока)
	РегистрыСведений.СтатусЗагрузки.ЗаписатьНачалоЧтения(Замер);
	
	Прогресс = 0;
	Разобрано = 0;
	МоментНачалаЧтения = ТекущаяУниверсальнаяДатаВМиллисекундах();
	Попытка
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеНачато");
		
		// временный файл нужен для копирования в него файлов логов, т.к. те которые в текущий момент пишуться не могут быть помещены во временное хранилище (1с ругается на невозможность получить доступ)
		ИмяВрФайла = ПолучитьИмяВременногоФайла("log");
		//...глАдресСтрокиСостояния = ОбновлениеДанных.ПолучитьАдресХранилища();
		Для каждого ПапкаТЖ Из ПапкиТЖ Цикл
			Индекс = Индекс + 1;
			ТекущийПрогресс = Прогресс;
			Прогресс = Индекс / ПапкиТЖ.Количество() * 100;
			ДиапазонПрогресса = Прогресс - ТекущийПрогресс;
			
			Если НЕ ЗначениеЗаполнено(КлючФоновогоЗадания) Тогда
				ФайлыТЖ = НайтиФайлы(ПапкаТЖ.ПолноеИмя, "*",Истина);
			Иначе
				ФайлыТЖ = ПапкаТЖ;
			КонецЕсли;
			
			// Получение параметров процесса
			Если НЕ ЗначениеЗаполнено(КлючФоновогоЗадания) Тогда
				ИмяПапки = ПапкаТЖ.Имя;
			Иначе
				ИмяПапки = ПапкаТЖ[0].ИмяПапки;
			КонецЕсли;
			ИмяПапки = СтрЗаменить(ИмяПапки, "_", Символы.ПС);
			Процесс = СтрПолучитьСтроку(ИмяПапки, 1);
			ПроцессID = СтрПолучитьСтроку(ИмяПапки, 2);
			КоличествоФайловТЖ = ФайлыТЖ.Количество();
			ИндексФайла = 0;
			Для Каждого ФайлТЖ Из ФайлыТЖ Цикл
				
				Если ЗначениеЗаполнено(КлючФоновогоЗадания) Тогда
					ИмяПапки = ФайлТЖ.ИмяПапки;
					ИмяПапки = СтрЗаменить(ИмяПапки, "_", Символы.ПС);
					Процесс = СтрПолучитьСтроку(ИмяПапки, 1);
					ПроцессID = СтрПолучитьСтроку(ИмяПапки, 2);					
				КонецЕсли;
				
				СвойстваФайла = ПолучитьВременныеПараметрыПоСвойствамФайла(ФайлТЖ);
				
				ДатаФайла = СвойстваФайла.ДатаФайла;
//				Год = СвойстваФайла.Год;
//				День = СвойстваФайла.День;
//				Месяц = СвойстваФайла.Месяц;
//				Час = СвойстваФайла.Час;  
				ИндексФайла = ИндексФайла + 1;
								
				СостояниеЧтения = РегистрыСведений.ГраницыЧтенияДанных.ПолучитьСостояние(Замер, Процесс, ПроцессID, ДатаФайла);
				Если СостояниеЧтения.ПрочитанПолностью Тогда
					Продолжить;
				КонецЕсли;		
						
				//Определение не получались ли уже по этому процессу данные за более поздний час
				//Если Не ОбновлениеДанных.ПроверитьНаличиеДанныхПоПроцессуЗаПериод(Замер,Процесс, ПроцессID, Дата(Год + 2000, Месяц, День, 0, 0, 0), Час) Тогда
					
					//... Если данные за более поздний час не получались - чтение файла, разбор и помещение в регистр
//					АдресФайла = "";
					КопироватьФайл(ФайлТЖ.ПолноеИмя, ИмяВрФайла);
					
					РазобраноСтрок = РазобратьФайл(Процесс, ПроцессID, ДатаФайла, ИмяВрФайла,Замер);
					
					ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.РазобранФайл",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания+" строк:"+РазобраноСтрок);
					УдалитьФайлы(ИмяВрФайла);
					Если КоличествоФайловТЖ*ДиапазонПрогресса=0 Тогда
						Прогресс = 100;
					Иначе
						Прогресс = ТекущийПрогресс + ИндексФайла / КоличествоФайловТЖ * ДиапазонПрогресса;
					КонецЕсли;
					
					Разобрано = Разобрано + РазобраноСтрок;
					РегистрыСведений.СтатусЗагрузки.ЗаписатьПрогресс(Замер, Прогресс, Разобрано);
				//КонецЕсли;
			КонецЦикла;
			Прогресс = Индекс / ПапкиТЖ.Количество() * 100;
			РегистрыСведений.СтатусЗагрузки.ЗаписатьПрогресс(Замер, Прогресс, Разобрано);
		КонецЦикла;
	Исключение
		РегистрыСведений.СтатусЗагрузки.ЗаписатьЗавршениеЧтения(Замер, Прогресс, Разобрано);
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеПрервано");
		ВызватьИсключение;
	КонецПопытки;
	МоментОкончанияЧтения = ТекущаяУниверсальнаяДатаВМиллисекундах();
	ДлительностьЧтения = (МоментОкончанияЧтения - МоментНачалаЧтения) / 1000;
	Прогресс = Индекс / ПапкиТЖ.Количество() * 100;
	РегистрыСведений.СтатусЗагрузки.ЗаписатьЗавршениеЧтения(Замер, Прогресс, Разобрано, ДлительностьЧтения);
	//ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеЗавершено");
	ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеЗавершено",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания);
КонецПроцедуры // ПрочитатьЖурнал 

#КонецОбласти

#Область ЧтениеЖурналаПотоками

Процедура ЗагрузкаТЖПотоками(Замер=Неопределено,КаталогТЖ="") Экспорт 
	
	РазмерНеобрабатываемогоФайла = 100;
	
	
	Если КаталогТЖ="" Тогда
		ТекстОшибки = "Каталог ТЖ должен быть заполнен!";
		ЗаписьЖурналаРегистрации("ОбновлениеДанных.ЗагрузкаТЖПотоками",УровеньЖурналаРегистрации.Ошибка,Неопределено,Замер,ТекстОшибки,);
		ВызватьИсключение ТекстОшибки;
	КонецЕсли;	
	
	// 1. Найдем файл из каталога ТЖ и загрузим информацию о них в регистр
	// и каталог должен быть доступен с сервера
	ПапкиТЖ = НайтиФайлы(КаталогТЖ, "*");
	
	Попытка
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеНачато");
	
		Для каждого ПапкаТЖ Из ПапкиТЖ Цикл
			
			ФайлыТЖ = НайтиФайлы(ПапкаТЖ.ПолноеИмя, "*",Истина);
			Для Каждого ФайлТЖ Из ФайлыТЖ Цикл
				
				Если ФайлТЖ.Размер()<=3 Тогда
					Продолжить;
				КонецЕсли;
				
				СвойстваФайла = ПолучитьВременныеПараметрыПоСвойствамФайла(ФайлТЖ); 
				
				ФоновоеЗаданиеЗапись = РегистрыСведений.УправлениеФоновымиЗаданиямиЗагрузки.СоздатьМенеджерЗаписи();
				ФоновоеЗаданиеЗапись.Имя = ФайлТЖ.Имя;
				ФоновоеЗаданиеЗапись.ИмяБезРасширения = ФайлТЖ.ИмяБезРасширения;
				ФоновоеЗаданиеЗапись.ПолноеИмя = ФайлТЖ.ПолноеИмя;
				ФоновоеЗаданиеЗапись.РазмерФайла = ФайлТЖ.Размер();
				ФоновоеЗаданиеЗапись.ИмяПапки = ФайлТЖ.Путь;
				ФоновоеЗаданиеЗапись.Замер = Замер;
				ФоновоеЗаданиеЗапись.ПутьКФайлу = ФайлТЖ.ПолноеИмя; 
				ФоновоеЗаданиеЗапись.Обработан = (РазмерНеобрабатываемогоФайла>ФоновоеЗаданиеЗапись.РазмерФайла);
				ФоновоеЗаданиеЗапись.КлючФоновогоЗадания = "";
				ФоновоеЗаданиеЗапись.Длительность = 0;
				ФоновоеЗаданиеЗапись.ДатаНачала = Неопределено;  			
           		ФоновоеЗаданиеЗапись.ДатаФайла = СвойстваФайла.ДатаФайла;
				
				ФоновоеЗаданиеЗапись.Записать();
				
			КонецЦикла;
		КонецЦикла;
	Исключение
		ТекстОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеПрервано",УровеньЖурналаРегистрации.Ошибка,Неопределено,Замер,ТекстОшибки,);
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;
	
	// 2. Разобьем по потокам
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	Т.Замер КАК Замер,
	|	Т.РазмерФайла КАК РазмерФайла,
	|	Т.Имя КАК Имя,
	|	Т.ИмяБезРасширения КАК ИмяБезРасширения,
	|	Т.ПолноеИмя КАК ПолноеИмя,
	|	Т.КоличествоФайловВсего КАК КоличествоФайловВсего,
	|	Т.ИмяПапки КАК ИмяПапки
	|ИЗ
	|	РегистрСведений.УправлениеФоновымиЗаданиямиЗагрузки КАК Т
	|ГДЕ
	|	Т.Замер = &Замер
	|	И Т.РазмерФайла > &РазмерНеобрабатываемогоФайла
	|	И Т.Обработан = ЛОЖЬ
	|
	|УПОРЯДОЧИТЬ ПО
	|	РазмерФайла УБЫВ";
	
	Запрос.УстановитьПараметр("Замер", Замер);
	Запрос.УстановитьПараметр("РазмерНеобрабатываемогоФайла",РазмерНеобрабатываемогоФайла);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	КолВоФоновыхЗаданий = Неопределено;
    МассивЗаданий = Неопределено;
    РазбитьФайлыПоФоновымЗаданиям(ВыборкаДетальныеЗаписи, КолВоФоновыхЗаданий, МассивЗаданий);

	
	// 3. Запускаем потоки и именно загрузка журнала в фоновых
	Ит=0;
	Пока Ит<=КолВоФоновыхЗаданий-1 Цикл
		
		КлючФоновогоЗадания = МассивЗаданий[Ит][0].КлючФоновогоЗадания;
		
		мПараметры = новый Массив;
		мПараметры.Добавить(Замер);
		//мПараметры.Добавить(МассивЗаданий[Ит]);
		мПараметры.Добавить(КлючФоновогоЗадания);
		
		ФоновоеЗадание = ФоновыеЗадания.Выполнить("ОбновлениеДанных.ПрочитатьЖурналПоРегистру",мПараметры,КлючФоновогоЗадания);
		
		Ит=Ит+1;
	КонецЦикла;
	
КонецПроцедуры

Процедура РазбитьФайлыПоФоновымЗаданиям(Знач ВыборкаДетальныеЗаписи, КолВоФоновыхЗаданий, МассивЗаданий)
	
	Перем Ит, ПервыйПроход;
	
	КолВоФоновыхЗаданий = Константы.МаксимальноеКолВоПотоковДляОднойЗагрузки.Получить();
	
	МассивЗаданий = Новый Массив;
	КлючиФоновогоЗадания = новый Соответствие();
	
	Ит=0;
	Пока Ит<=КолВоФоновыхЗаданий-1 Цикл
		
		МассивЗаданий.Добавить(Новый Массив);
		КлючиФоновогоЗадания.Вставить(Ит,"ФоновоеЗадание"+Ит+"  "+Новый УникальныйИдентификатор);		
		Ит = Ит+1;
		
	КонецЦикла;
	
//	Шаг = 0;
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		ПервыйПроход = Истина;	
		Ит=0;
		Пока Ит<=КолВоФоновыхЗаданий-1 Цикл
			
			Если ПервыйПроход Тогда
				ДобавитьФоновоеЗадание(МассивЗаданий[Ит], ВыборкаДетальныеЗаписи,КлючиФоновогоЗадания.Получить(Ит));
				ПервыйПроход = Ложь;
				Ит=Ит+1;
				Продолжить;
			КонецЕсли;		
			
			Если ВыборкаДетальныеЗаписи.Следующий() Тогда
				ДобавитьФоновоеЗадание(МассивЗаданий[Ит], ВыборкаДетальныеЗаписи,КлючиФоновогоЗадания.Получить(Ит));	
			Иначе
				Прервать;
			КонецЕсли;
			
			Ит=Ит+1;
		КонецЦикла;
		
		Ит=КолВоФоновыхЗаданий-1;
		Пока Ит<>-1 Цикл
			
			Если ВыборкаДетальныеЗаписи.Следующий() Тогда
				ДобавитьФоновоеЗадание(МассивЗаданий[Ит], ВыборкаДетальныеЗаписи,КлючиФоновогоЗадания.Получить(Ит));
			Иначе
				Прервать;
			КонецЕсли;
			
			Ит = Ит-1;
		КонецЦикла;
		
	КонецЦикла;

КонецПроцедуры

Процедура УстановитьКлючФоновогоЗадания(Замер,ПутьКФайлу,КлючФоновогоЗадания)
	
	МенеджерЗаписи = РегистрыСведений.УправлениеФоновымиЗаданиямиЗагрузки.СоздатьМенеджерЗаписи();
	МенеджерЗаписи.Замер = Замер;
	МенеджерЗаписи.ПутьКФайлу = ПутьКФайлу;
	МенеджерЗаписи.Прочитать();
	
	МенеджерЗаписи.КлючФоновогоЗадания = КлючФоновогоЗадания;
	МенеджерЗаписи.Записать(Истина);	
	
КонецПроцедуры

Процедура УстановитьСвойствоУправленияФоновымиЗаданиями(Замер,ПутьКФайлу,КлючФоновогоЗадания,Свойство,Значение)
	
	МенеджерЗаписи = РегистрыСведений.УправлениеФоновымиЗаданиямиЗагрузки.СоздатьМенеджерЗаписи();
	МенеджерЗаписи.Замер = Замер;
	МенеджерЗаписи.ПутьКФайлу = ПутьКФайлу;
	МенеджерЗаписи.КлючФоновогоЗадания = КлючФоновогоЗадания;
	МенеджерЗаписи.Прочитать();
	
	МенеджерЗаписи[Свойство] = Значение;
	МенеджерЗаписи.Записать(Истина);
	
КонецПроцедуры

Процедура ДобавитьФоновоеЗадание(МассивЗаданий, ВыборкаДетальныеЗаписи, КлючФоновогоЗадания)
	
	МассивЗаданий.Добавить(Новый Структура("Замер,РазмерФайла,Имя,ИмяБезРасширения,ПолноеИмя,КоличествоФайловВсего,ИмяПапки,КлючФоновогоЗадания",
	ВыборкаДетальныеЗаписи.Замер,
	ВыборкаДетальныеЗаписи.РазмерФайла,
	ВыборкаДетальныеЗаписи.Имя,
	ВыборкаДетальныеЗаписи.ИмяБезРасширения,
	ВыборкаДетальныеЗаписи.ПолноеИмя,
	ВыборкаДетальныеЗаписи.КоличествоФайловВсего,
	ВыборкаДетальныеЗаписи.ИмяПапки,
	КлючФоновогоЗадания));
	
	УстановитьКлючФоновогоЗадания(ВыборкаДетальныеЗаписи.Замер,ВыборкаДетальныеЗаписи.ПолноеИмя,КлючФоновогоЗадания);
	
КонецПроцедуры

Функция ПолучитьНеОбработаннеФайлыПоРегистру(Замер,КлючФоновогоЗадания)
	
	Запрос = новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	|	Т.Замер КАК Замер,
	|	Т.ПутьКФайлу КАК ПутьКФайлу,
	|	Т.Обработан КАК Обработан,
	|	Т.КлючФоновогоЗадания КАК КлючФоновогоЗадания,
	|	Т.ДатаФайла КАК ДатаФайла,
	|	Т.Длительность КАК Длительность,
	|	Т.ДатаНачала КАК ДатаНачала,
	|	Т.РазмерФайла КАК РазмерФайла,
	|	Т.Имя КАК Имя,
	|	Т.ИмяБезРасширения КАК ИмяБезРасширения,
	|	Т.ПолноеИмя КАК ПолноеИмя,
	|	Т.КоличествоФайловВсего КАК КоличествоФайловВсего,
	|	Т.ИмяПапки КАК ИмяПапки,
	|	ВЫРАЗИТЬ(Т.ИмяПапки КАК СТРОКА(250)) КАК ИмяПапкиДляУпорядочивания
	|ИЗ
	|	РегистрСведений.УправлениеФоновымиЗаданиямиЗагрузки КАК Т
	|ГДЕ
	|	Т.Замер = &Замер
	|	И Т.КлючФоновогоЗадания = &КлючФоновогоЗадания
	|	И Т.Обработан = ЛОЖЬ
	|
	|УПОРЯДОЧИТЬ ПО
	|	ИмяПапкиДляУпорядочивания,
	|	ДатаФайла";
	Запрос.УстановитьПараметр("Замер",Замер);
	Запрос.УстановитьПараметр("КлючФоновогоЗадания",КлючФоновогоЗадания);	
	
	Возврат Запрос.Выполнить().Выгрузить();
	
КонецФункции

Процедура ПрочитатьЖурналПоРегистру(Замер=Неопределено,КлючФоновогоЗадания="") Экспорт
	
	ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеНачато",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания);
	
	Если НЕ ЗначениеЗаполнено(КлючФоновогоЗадания) Тогда
		ВызватьИсключение "Ключ фонового задания быть заполнен!";
	КонецЕсли;
	
	ФайлыТЖ = ПолучитьНеОбработаннеФайлыПоРегистру(Замер,КлючФоновогоЗадания);
	
	Индекс = 0;
//	МоментНачалаЧтения = ТекущаяУниверсальнаяДатаВМиллисекундах();
	НужноКопировать = ?(ЗначениеЗаполнено(Замер),НЕ Замер.НеРабочийКаталог,Истина);
	
	Попытка
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеНачато");
		
		// временный файл нужен для копирования в него файлов логов, т.к. те которые в текущий момент пишуться не могут быть помещены во временное хранилище (1с ругается на невозможность получить доступ)
		ИмяВрФайла = ПолучитьИмяВременногоФайла("log");
		
		Индекс = Индекс + 1;
		
		Для Каждого ФайлТЖ Из ФайлыТЖ Цикл
			
			ИмяПапки = ФайлТЖ.ИмяПапки;
			
			МассивПапок = новый Массив;
			
			Если Найти(ИмяПапки,"\") Тогда
				МассивПапок = СтрРазделить(ИмяПапки,"\",Ложь);
			Иначе
				МассивПапок = СтрРазделить(ИмяПапки,"/",Ложь);
			КонецЕсли;
			
			ИмяПапки = МассивПапок[МассивПапок.ВГраница()];
			
			ИмяПапки = СтрЗаменить(ИмяПапки, "_", Символы.ПС);
			Процесс = СтрПолучитьСтроку(ИмяПапки, 1);
			ПроцессID = СтрПолучитьСтроку(ИмяПапки, 2);
//			КоличествоФайловТЖ = ФайлыТЖ.Количество();
			ИндексФайла = 0;  			
			
			СвойстваФайла = ПолучитьВременныеПараметрыПоСвойствамФайла(ФайлТЖ);
			
            ДатаФайла = СвойстваФайла.ДатаФайла;
//			Год = СвойстваФайла.Год;
//            День = СвойстваФайла.День;
//            Месяц = СвойстваФайла.Месяц;
//            Час = СвойстваФайла.Час;      
			ДатаНачалаОбработки = ТекущаяДата();
			
			УстановитьСвойствоУправленияФоновымиЗаданиями(Замер,ФайлТЖ.ПолноеИмя,КлючФоновогоЗадания,"ДатаНачала",ДатаНачалаОбработки);

			
			ИндексФайла = ИндексФайла + 1;
			
			СостояниеЧтения = РегистрыСведений.ГраницыЧтенияДанных.ПолучитьСостояние(Замер, Процесс, ПроцессID, ДатаФайла);
			Если СостояниеЧтения.ПрочитанПолностью Тогда
				Продолжить;
			КонецЕсли;		
			
			//Определение не получались ли уже по этому процессу данные за более поздний час
//			Если Не ПроверитьНаличиеДанныхПоПроцессуЗаПериод(Замер,Процесс, ПроцессID, Дата(Год + 2000, Месяц, День, 0, 0, 0), Час) Тогда
				
				//... Если данные за более поздний час не получались - чтение файла, разбор и помещение в регистр
//				АдресФайла = "";
				Если НужноКопировать=Истина Тогда
					КопироватьФайл(ФайлТЖ.ПолноеИмя, ИмяВрФайла);
				Иначе
					ИмяВрФайла = ФайлТЖ.ПолноеИмя;
				КонецЕсли;
				РазобраноСтрок = РазобратьФайл(Процесс, ПроцессID, ДатаФайла, ИмяВрФайла, Замер);
				УстановитьСвойствоУправленияФоновымиЗаданиями(Замер,ФайлТЖ.ПолноеИмя,КлючФоновогоЗадания,"Разобрано",РазобраноСтрок);
				ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.РазобранФайл",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания+" строк:"+РазобраноСтрок);
				Если НужноКопировать=Истина Тогда
					УдалитьФайлы(ИмяВрФайла);
				КонецЕсли;
				
//			КонецЕсли;
			
			УстановитьСвойствоУправленияФоновымиЗаданиями(Замер,ФайлТЖ.ПолноеИмя,КлючФоновогоЗадания,"Обработан",Истина);
			УстановитьСвойствоУправленияФоновымиЗаданиями(Замер,ФайлТЖ.ПолноеИмя,КлючФоновогоЗадания,"Длительность",ТекущаяДата()-ДатаНачалаОбработки);
			
		КонецЦикла;
		
	Исключение
		ТекстОшибки = ОписаниеОшибки();
		ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеПрервано",УровеньЖурналаРегистрации.Ошибка,Неопределено,Замер,ТекстОшибки,);
		ВызватьИсключение ТекстОшибки;
	КонецПопытки;
	
	ЗаписьЖурналаРегистрации("ЧтениеЖурналаРегистрации.ЧтениеЗавершено",УровеньЖурналаРегистрации.Предупреждение,,,КлючФоновогоЗадания);
	
КонецПроцедуры

#КонецОбласти

#Область Служебные

Функция ОчиститьЖурналы(Замер) Экспорт
	
	НаборЗаписей = РегистрыСведений.Журнал.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Замер.Установить(Замер);
	НаборЗаписей.Записать();
	
	НаборЗаписей = РегистрыСведений.СвойстваСобытия.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Замер.Установить(Замер);
	НаборЗаписей.Записать();
	
	НаборЗаписей = РегистрыСведений.ГраницыЧтенияДанных.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Замер.Установить(Замер);
	НаборЗаписей.Записать();

	НаборЗаписей = РегистрыСведений.УправлениеФоновымиЗаданиямиЗагрузки.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Замер.Установить(Замер);
	НаборЗаписей.Записать();

	НаборЗаписей = РегистрыСведений.СтатусЗагрузки.СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Замер.Установить(Замер);
	НаборЗаписей.Записать();
	
	Возврат Истина;
	
КонецФункции

Функция ИнформационнаяБазаФайловая(Знач СтрокаСоединенияИнформационнойБазы = "") Экспорт
			
	Если ПустаяСтрока(СтрокаСоединенияИнформационнойБазы) Тогда
		СтрокаСоединенияИнформационнойБазы =  СтрокаСоединенияИнформационнойБазы();
	КонецЕсли;
	Возврат Найти(Врег(СтрокаСоединенияИнформационнойБазы), "FILE=") = 1;
	
КонецФункции 

#КонецОбласти