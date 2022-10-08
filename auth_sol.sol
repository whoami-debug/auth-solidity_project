// указываем версию компилятора
pragma solidity >0.7.0;
pragma experimental ABIEncoderV2;


contract Change {
    
	// структура Пользователь
    struct User {
        uint balance;		// баланс
        bytes32 pwhash;		// хэщ пароля пользователя
        bool role;			// роль пользователя, false - пользователь, true - админ
    }
    
	// информация о пользователях в системе
    mapping (address => User) public users;
    
	// список адресов пользователей системы
	address[] public userlist;
    
    struct Transfer {
        address adr_from;       // адрес от кого
        address adr_to;         // адрес кому
        uint value;             // сумма перевода
        uint category;          // категория перевода
        string description;     // описание перевода
        bytes32 pwhash;         // хэш keccak256 кодового слова
        uint time;              // время перевода, UNIX-time
        bool finished;          // завершен или нет
    }
    
	// информация о переводах
    mapping(uint => Transfer) public transfers;
	
	// количество переводов в системе
    uint public transfer_amount;
    
    // наименования категорий
    string[] public categories;
    
    // структура шаблона
    struct Template {   // шаблон
        uint category;
        uint value;
    }
    
    // список всех шаблонов
    mapping (string => Template) public templates;
	
    // наименования существующих шаблонов
    string[] template_names;
    
    // количество администраторов
    uint public admin_amount;
    
    // предложения на повышение роли
    struct BoostOffer {
        address to_boost;		// пользователь, которого повышают в админы
        address[] proc; 		// голоса ЗА
        address cons; 			// голоса ПРОТИВ
        bool finished;  		// завершилось ли голосование
    }
    mapping (uint => BoostOffer) public boosts; // все предложения на повышение
    uint public offer_amount;
    
    constructor() public {
        
        //пароль 123
        //обычные пользователи
        users[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, false);
        users[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, false);
        users[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, false);
        users[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, false);
        // администраторы
        users[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, true);
        users[0x617F2E2fD72FD9D5503197092aC168c91465E7f2] = User(1000, 0x64e604787cbf194841e7b68d7cd28786f6c9a0a3ab9f8b0a0e87cb4387ab0107, true);
        // добавляем пользователей в список пользователей
        userlist.push(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        userlist.push(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);
        userlist.push(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c);
        userlist.push(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);
        userlist.push(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB);
        userlist.push(0x617F2E2fD72FD9D5503197092aC168c91465E7f2);
        
        // количество администраторов
        admin_amount = 2;
        
        // описываем уже существующие категории
        categories.push("0 - Lichnii perevod");
        categories.push("1 - Oplata arendi zhil'ya");
        categories.push("2 - Lichnie vzaimoracsheti");
        
        // описываем уже существующие шаблоны
        templates["Podarok 10"] = Template(0, 10);
        templates["Podarok 30"] = Template(0, 30);
        templates["Podarok 50"] = Template(0, 50);
        templates["Kvartplata 70"] = Template(1, 70);
        templates["Kvartplata 90"] = Template(1, 90);
        templates["Pogashenie zadolzhennosti 100"] = Template(2, 100);
        
        // наименование существующих шаблонов
        template_names = ["Podarok 10", "Podarok 30", "Podarok 50", "Kvartplata 70", "Kvartplata 90", "Pogashenie zadolzhennosti 100"];
    }
    
    
    // Управление пользователями
    
    // регистрация нового пользователя
    function create_user(bytes32 pwhash) public {
        require(users[msg.sender].pwhash == 0, "error: user already exist"); 		// пользователь уже существует, нельзя зарегистрировать заново
        users[msg.sender] = User(0, pwhash, false);
        userlist.push(msg.sender);
    }

    // получить список пользователей
    function get_userlist() view public returns(address[] memory) {
        return userlist;
    }
    
    function get_users_amount() public view returns(uint) {
        return userlist.length;
    }
    
    
    
    // управление категориями
    
    // создать новую категорию
    function create_category(string memory name) public onlyAdmin {
        categories.push(name);
    }
    
    //получить список существующих категорий
    function get_categories() public view returns(string[] memory) {
        return categories;
    }
    
    
    //управление шаблонами
    
    //Создать новый шаблон
    function create_template(string memory name, uint category, uint value) public onlyAdmin {
        require(category>=0 && category<categories.length, "error: no such category"); 		//ошибка, несуществующая категория
        require(value > 0, "error: wrong value");       									// ошибка, неправильная сумма перевода
        templates[name] = Template(category, value);
        template_names.push(name);
    }
    
    //получить информацию о шаблоне по имени
    //function get_template_by_name()
    
    //получить список наименований шаблонов
    function get_template_names() public view returns(string[] memory) {
        return template_names;
    }
    
    
    //функционал переводов
    
    //создание нового перевода
    function create_transfer(address adr_to, uint value, uint category, string memory description, bytes32 pwhash) public {
        require(users[msg.sender].balance >= value, "not enought money"); 												// ошибка, недостаточно средств
        require(value > 0, "eroor: wrong value"); 																		//неверная сумма
        require(category>=0 && category<categories.length, "error: no such category"); 									//ошибка, несуществующая категория
        require(msg.sender != adr_to, "error: transfer to yourself"); 													//перевод самому себе
        require(users[adr_to].pwhash != 0, "error: user doesn't exist"); 												// пользователь не существует
        transfers[transfer_amount] = Transfer(msg.sender, adr_to, value, category, description, pwhash, 0, false);  	// создаем перевод        
        transfer_amount += 1;																							// увеличиваем количество переводов на 1
        users[msg.sender].balance -= value;     																		// уменьшаем баланс отправителя
    }
    
    //использование шаблонами
    function use_template(address adr_to, string memory template, string memory description, bytes32 pwhash) public {
        uint value = templates[template].value;
        require(value != 0, "error: template doesn't exist"); 					// нет такого шаблона
        uint category = templates[template].category;
        create_transfer(adr_to, value, category, description, pwhash);			// создать перевод на основе данных шаблона
    }
    
    //отменить свой перевод, пока получатель его не успел принять
    function stop_my_transfer(uint tr_id) public {
        require(transfers[tr_id].adr_from == msg.sender, "error: it's not your transfer"); 		// нельзя отменить чужой перевод
        require(transfers[tr_id].finished == false, "error: already finished"); 				// деньги уже приняты или перевод уже отменет
        transfers[tr_id].finished = true;														// завершить перевод
        users[msg.sender].balance += transfers[tr_id].value;									// вернуть деньги отправителю
    }
    
    //получить перевод, используя  кодовое слово
    function get_my_transfer(uint tr_id, string memory pw) public {
        require(transfers[tr_id].adr_to == msg.sender, "error: not for you"); 		// перевод не для вас
        require(transfers[tr_id].finished == false, "error: already finished"); 	// деньги уже приняты или перевод уже отменет
        bytes32 pwhash = keccak256(abi.encodePacked(pw));   						// преобразовываем кодовое слово в байты и хешируем его
        //require(pwhash == transfers[tr_id].pwhash, "error: wrong password");		// ошибка "неверный пароль"
        if (pwhash == transfers[tr_id].pwhash) {									// если пероль верный, то перевести деньги получателю
            users[msg.sender].balance += transfers[tr_id].value;
            transfers[tr_id].time = block.timestamp;								// внести время перевода
        }
        else {																		// если пароль неверный, то деньги возвращаются отправителю
            address adr_from = transfers[tr_id].adr_from;	
            users[adr_from].balance += transfers[tr_id].value;
        }
        transfers[tr_id].finished = true;											// голосование завершается
    }
    
    
    //Функционал администратора
    
    //модификатор доступа " только администратор"
    modifier onlyAdmin() {
        require(users[msg.sender].role, "error: you are not admin"); 				//ошибка "вы не админ"
        _;
    }
    
    //предложить пользователя на роль администратора 
    function offer_user_to_boost(address user_adr) public onlyAdmin {
        require(users[user_adr].pwhash != 0, "error: user doesn't exist"); 			// пользователь не существует
        require(users[user_adr].role == false, "error: already admin"); 			// уже и так администратор
        address[] memory zerroArray;												// пустой список адресов						
        boosts[offer_amount] = BoostOffer(user_adr, zerroArray, address(0), false);	// создать новое голосование
        boosts[offer_amount].proc.push(msg.sender);									// кто создал объявление, тот проголосовал сразу ЗА
        offer_amount += 1;															// увеличить количество голосований в системе
    }
    
    //Получить список голосов ЗА
    function get_proc(uint offer_id) public view returns(address[] memory) {
        return boosts[offer_id].proc;
    } 
    
	//проверяем не проголосовал ли пользователь уже
    modifier checkVote(uint offer_id) {      
        bool vote = false;
        for (uint i = 0; i < boosts[offer_id].proc.length; i++) { 	//смотрим на весь список голосов ЗА и ищем там админа, который пытается проголосовать
            if (boosts[offer_id].proc[i] == msg.sender) {
                vote = true;
                break;
            }
        }
        require(vote == false, "error: already voted"); // ошибка, уже проголосовал
        _;
    }
    
	//проверить что голосолвание успешно завершено, назначить нового админа
    function check_offer(uint offer_id) public onlyAdmin { 
        if (boosts[offer_id].proc.length == admin_amount) {		// если все админы проголосовали ЗА
            boosts[offer_id].finished = true;					// завершить голосование
            address user_adr = boosts[offer_id].to_boost;		
            users[user_adr].role = true;						// назначить пользователю роль админа
            admin_amount += 1;									// увеличить количество админов на 1
        }
    }
    
    //голосую ЗА
    function vote_for(uint offer_id) public onlyAdmin checkVote(offer_id) {
        require(boosts[offer_id].finished == false, "error: already finished"); 	// уже завершено
        boosts[offer_id].proc.push(msg.sender);										// добавить адрес в список голосующих ЗА
        check_offer(offer_id);														// нужно ли завершить голосование? все ли проголосовали ЗА
    }
    
    //голосовать ПРОТИВ
    function vote_against(uint offer_id) public onlyAdmin checkVote(offer_id) {
        require(boosts[offer_id].finished == false, "error: already finished"); 	// уже завершено
        boosts[offer_id].cons = msg.sender;											// записать кто голосовал ПРОТИВ
        boosts[offer_id].finished = true;											// завершить голосование
    }
    
}

