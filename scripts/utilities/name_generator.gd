class_name NameGenerator
extends RefCounted

## Generates era-appropriate names for souls with authentic historical accuracy

# PREHISTORIC ERA - Organized by civilization to prevent mixing
const PREHISTORIC_CIVILIZATIONS = [
	# Celtic
	{
		"first_names": ["Boudicca", "Brennus", "Cunobelinus", "Vercingetorix", "Caratacus", "Togodumnus", "Cartimandua",
			"Conan", "Brenna", "Cathal", "Deirdre", "Eamon", "Fiona", "Gavin", "Maeve", "Niall", "Rhiannon",
			"Alwyn", "Briallen", "Cadoc", "Derwyn", "Emrys", "Ffion", "Gethin", "Heledd", "Idris", "Lowri"],
		"last_names": ["son of Celtillus", "daughter of Brennus", "of the Oak Grove", "Belgae", "Iceni",
			"Catuvellauni", "Trinovantes", "Brigantes", "Dobunni", "Silures", "the Tall", "the Wise",
			"the Swift", "the Brave", "of the Forest", "of the Hills"]
	},
	# Germanic
	{
		"first_names": ["Adalbern", "Adalhard", "Agilulf", "Alaric", "Arminius", "Theodoric", "Clovis", "Childeric",
			"Brunhild", "Kriemhild", "Berengar", "Clothilde", "Ermengarde", "Fredegund", "Gisela", "Hildegard",
			"Ingomar", "Liutgard", "Roswitha", "Wulfila"],
		"last_names": ["Cherusci", "Suebi", "Alamanni", "Franks", "Goths", "Vandals", "Burgundians", "Lombards",
			"the Strong", "the Dark", "the Fair", "Ironhand", "Stormborn", "of the River", "of the Mountains"]
	},
	# Proto/Elemental
	{
		"first_names": ["Ash", "Bear", "Birch", "Clay", "Dawn", "Elk", "Fire", "Frost", "Hawk", "Iron",
			"Leaf", "Moon", "Oak", "Rain", "Reed", "Sky", "Stone", "Storm", "Sun", "Wolf"],
		"last_names": ["Bearslayer", "Ironhand", "Moonwalker", "Firekeeper", "Wolffriend", "Ravenfeather", "Eagleeye",
			"the Silent", "of the Plains", "of the Shore", "of the Cave", "of the Valley"]
	}
]

# ANCIENT ERA - Organized by civilization to prevent mixing
const ANCIENT_CIVILIZATIONS = [
	# Ancient Egyptian
	{
		"first_names": ["Ramesses", "Ahmose", "Akhenaton", "Amenhotep", "Hatshepsut", "Tutankhamun", "Khufu",
			"Nefertiti", "Thutmose", "Nefertari", "Ankhsenamun", "Horemheb", "Seti", "Senusret", "Mentuhotep",
			"Ay", "Tiye", "Meritaten"],
		"last_names": ["beloved of Ra", "chosen of Amun", "son of Ptah", "daughter of Isis", "of Thebes",
			"of Memphis", "of Heliopolis", "the Builder", "the Conqueror", "the Divine", "the Great",
			"the Wise", "the Just"]
	},
	# Mesopotamian
	{
		"first_names": ["Sargon", "Hammurabi", "Ur-Nammu", "Shulgi", "Gilgamesh", "Enkidu", "Naram-Sin",
			"Enheduanna", "Kubaba", "Puabi", "Ashurbanipal", "Sennacherib", "Nebuchadnezzar", "Cyrus",
			"Darius", "Xerxes", "Esarhaddon", "Tiglath-Pileser"],
		"last_names": ["of Akkad", "of Ur", "of Babylon", "of Assyria", "of Sumer", "of Nineveh", "of Uruk",
			"king of kings", "shepherd of the people", "mighty hunter", "wise lawgiver"]
	},
	# Ancient Chinese
	{
		"first_names": ["帝辛", "武丁", "盘庚", "妇好", "姬发", "姬昌", "姬旦", "姜尚", "比干",
			"商汤", "伊尹", "周公", "召公", "太公望", "纣王", "文王", "武王", "成王", "康王"],
		"last_names": ["姬", "姜", "嬴", "姚", "妫", "姒", "妘", "娸", "姞", "妊",
			"of Shang", "of Zhou", "of Qi", "of Jin", "of Qin", "of Chu", "of Yan", "of Wei"]
	},
	# Ancient Greek
	{
		"first_names": ["Alcibiades", "Alexander", "Demosthenes", "Leonidas", "Pericles", "Socrates", "Plato",
			"Aristotle", "Themistocles", "Aspasia", "Sappho", "Hipparchia", "Pythagoras", "Herodotus",
			"Thucydides", "Euripides", "Sophocles", "Aeschylus"],
		"last_names": ["son of Philip", "daughter of Cleisthenes", "of Athens", "of Sparta", "of Thebes",
			"of Corinth", "of Macedonia", "the Athenian", "the Spartan", "the Macedonian", "the Theban"]
	},
	# Ancient Roman
	{
		"first_names": ["Lucius", "Gaius", "Marcus", "Publius", "Quintus", "Titus", "Gnaeus", "Aulus",
			"Decimus", "Servius", "Julia", "Cornelia", "Livia", "Octavia", "Claudia", "Tullia",
			"Pompeia", "Calpurnia", "Aurelia", "Terentia"],
		"last_names": ["Cornelius Scipio", "Julius Caesar", "Claudius Nero", "Tullius Cicero",
			"Aurelius Antoninus", "Cornelius", "Julius", "Claudius", "Aurelius", "Valerius",
			"Flavius", "Antonius", "Aemilius"]
	}
]

# CLASSICAL ERA - Organized by civilization to prevent mixing
const CLASSICAL_CIVILIZATIONS = [
	# Byzantine/Eastern Roman
	{
		"first_names": ["Constantine", "Justinian", "Theodora", "Basil", "Alexios", "Irene", "Heraclius",
			"Zoe", "Michael", "Anna", "Nikephoros", "Maria", "John", "Helena", "Leo"],
		"last_names": ["Palaiologos", "Komnenos", "Doukas", "Angelos", "Phokas", "Botaneiates",
			"Dalassenos", "Diogenes"]
	},
	# Islamic Golden Age
	{
		"first_names": ["محمد", "عمر", "عثمان", "علي", "فاطمة", "عائشة", "خديجة", "حسن", "حسين",
			"صلاح الدين", "Harun", "المأمون", "Ibn Sina", "Ibn Rushd", "Al-Khwarizmi"],
		"last_names": ["al-Rashid", "ibn Sina", "ibn Rushd", "al-Khwarizmi", "al-Biruni", "al-Razi",
			"ibn Battuta", "الرشيد", "بن سينا", "بن رشد", "الخوارزمي"]
	},
	# Medieval Chinese
	{
		"first_names": ["李世民", "武则天", "杨贵妃", "李白", "杜甫", "王维", "白居易", "苏轼", "岳飞",
			"文天祥", "忽必烈", "成吉思汗", "朱元璋", "郑和", "王阳明"],
		"last_names": ["唐", "宋", "元", "明", "of Tang", "of Song", "of Yuan", "of Ming"]
	},
	# Medieval European
	{
		"first_names": ["William", "Richard", "Henry", "Edward", "Robert", "Thomas", "Geoffrey", "Hugh",
			"Roger", "Baldwin", "Eleanor", "Matilda", "Isabella", "Philippa", "Joan", "Margaret",
			"Elizabeth", "Catherine", "Anne", "Charlemagne", "Louis", "Charles", "Otto", "Frederick"],
		"last_names": ["of Normandy", "of Aquitaine", "of Anjou", "Plantagenet", "Capet", "Valois",
			"Habsburg", "Hohenstaufen", "de Montfort", "de Bohun", "FitzGerald", "Marshal", "Clare",
			"Neville", "Percy", "Douglas"]
	},
	# Medieval Japanese
	{
		"first_names": ["源頼朝", "平清盛", "北条時宗", "足利尊氏", "織田信長", "豊臣秀吉", "徳川家康",
			"武田信玄", "上杉謙信", "紫式部", "清少納言", "和泉式部", "小野小町"],
		"last_names": ["源", "平", "藤原", "橘", "豊臣", "徳川", "織田", "武田", "上杉", "北条",
			"Minamoto", "Taira", "Fujiwara", "Toyotomi", "Tokugawa", "Oda", "Takeda", "Uesugi"]
	},
	# Medieval Indian
	{
		"first_names": ["Akbar", "Ashoka", "Chandragupta", "Harsha", "Rajendra", "Krishnadevaraya",
			"Prithviraj", "Razia", "अशोक", "चंद्रगुप्त", "अकबर", "शिवाजी"],
		"last_names": ["Maurya", "Gupta", "Chola", "Chalukya", "Mughal", "Maratha", "Rajput", "Vijayanagara"]
	}
]

# MODERN ERA - Contemporary international names (can mix)
const MODERN_FIRST_NAMES = [
	# East Asian
	"明", "雪", "美", "晨", "林", "広", "桜", "光", "蓮", "結衣",
	"陽翔", "花", "空", "海斗", "澪", "陸", "凛", "愛子", "健二", "大輔",
	"伟", "秀", "建", "玲", "芳", "燕", "波", "君", "平", "丽",
	"서준", "지우", "민서", "하은", "지훈", "서연", "예준", "수아", "도윤", "하윤",
	# South Asian
	"Arjun", "Priya", "Raj", "Ananya", "Dev", "Isha", "Rohan", "Diya", "Amit", "Kavya",
	"Aditya", "Shreya", "Vikram", "Neha", "Karan", "Aditi", "Sanjay", "Rahul", "Anjali",
	# Middle Eastern
	"Ali", "Fatima", "Omar", "Layla", "Hassan", "Zara", "Karim", "Nadia", "Samir", "Amina",
	"Yusuf", "Aisha", "Ibrahim", "Maryam", "Ahmed", "Zaynab", "Tariq", "Rania",
	# African
	"Kwame", "Nia", "Jabari", "Zuri", "Kofi", "Amara", "Malik", "Ayana", "Chike", "Adanna",
	"Jelani", "Sanaa", "Thabo", "Nala", "Amani", "Ife", "Makena", "Safiya",
	# European/Slavic
	"Marco", "Sofía", "Luca", "Elena", "Иван", "Наташа", "Lars", "Freya", "Sven", "Astrid",
	"Дмитрий", "Аня", "Борис", "Катя", "Виктор", "Ирина", "Felix", "Greta", "Otto", "Mila",
	# Latin American
	"Diego", "Carmen", "Miguel", "Lucía", "Carlos", "Isabella", "Pablo", "María", "Juan", "Rosa",
	"Mateo", "Valentina", "Santiago", "Camila", "Alejandro", "Gabriel", "Rafael", "Natalia",
	# English/Western
	"James", "Emma", "William", "Olivia", "Noah", "Ava", "Ethan", "Sophia", "Mason", "Mia",
	"Benjamin", "Charlotte", "Lucas", "Amelia", "Henry", "Harper", "Alexander", "Evelyn",
	# Indigenous/Pacific
	"Koa", "Leilani", "Tane", "Moana", "Aroha", "Kai", "Hine", "Maui", "Keanu", "Alani"
]

const MODERN_LAST_NAMES = [
	# East Asian
	"李", "王", "张", "刘", "陈", "杨", "黄", "赵", "周", "吴",
	"佐藤", "鈴木", "高橋", "田中", "渡辺", "伊藤", "山本", "中村", "小林", "加藤",
	"김", "이", "박", "최", "정", "강", "조", "윤", "장", "임",
	# South Asian
	"Patel", "Singh", "Kumar", "Sharma", "Das", "Reddy", "Gupta", "Joshi", "Khan", "Rahman",
	"Shah", "Desai", "Rao", "Nair", "Verma", "Agarwal", "Mehta", "Kapoor",
	# Middle Eastern
	"Al-Rashid", "Hassan", "Mahmoud", "Khalil", "Abbas", "Nasser", "Saleh", "Tariq",
	"Al-Sayed", "Mansour", "Haddad", "Farah", "Nassar", "Khoury",
	# African
	"Okafor", "Mensah", "Diallo", "Mwangi", "Adebayo", "Nkosi", "Kamau", "Traore", "Eze", "Banda",
	"Okoro", "Nwosu", "Onyango", "Kimani", "Kone", "Toure", "Ndlovu", "Moyo",
	# European/Slavic
	"Rossi", "Schmidt", "Müller", "García", "López", "Novák", "Kowalski", "Попов", "Silva", "Costa",
	"Иванов", "Петров", "Волков", "Соколов", "Romano", "Ferrari", "Weber", "Wagner",
	# Latin American
	"Rodríguez", "Martínez", "Hernández", "González", "Fernández", "Morales", "Vargas", "Castillo",
	"Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Cruz", "Moreno",
	# English/Western
	"Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Wilson", "Moore", "Taylor",
	"Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Robinson",
	# Indigenous/Pacific
	"Kealoha", "Makoa", "Rangi", "Waititi", "Mahina", "Kahale", "Aroha", "Tamati", "Wiremu", "Ngata"
]

# Era-appropriate titles (with international variants)
const PREHISTORIC_TITLES = [
	"", "", "", "", "",  # 80% no title
	"Elder", "Chief", "Shaman", "Hunter", "Warrior",
	"长老", "酋长", "巫师", "猎人", "战士",  # Chinese
	"старейшина", "вождь", "шаман"  # Russian
]

const ANCIENT_TITLES = [
	"", "", "", "", "",  # 80% no title
	"Pharaoh", "Emperor", "Consul", "Oracle", "Sage", "General", "Priest",
	"法老", "皇帝", "执政官", "神谕者", "圣人", "将军", "祭司",  # Chinese
	"Фараон", "Император", "Оракул", "Мудрец", "Генерал", "Жрец"  # Russian
]

const CLASSICAL_TITLES = [
	"", "", "", "", "",  # 80% no title
	"Caesar", "Senator", "Philosopher", "Gladiator", "Centurion", "Magistrate",
	"凯撒", "元老", "哲学家", "角斗士", "百夫长", "执政官",  # Chinese
	"Цезарь", "Сенатор", "Философ", "Гладиатор"  # Russian
]

const MODERN_TITLES = [
	"", "", "", "", "",  # 80% no title
	"Dr.", "Professor", "Captain", "Agent", "Detective", "Sergeant",
	"博士", "教授", "上尉", "特工", "侦探", "中士",  # Chinese
	"Доктор", "Профессор", "Капитан", "Агент", "Детектив", "Сержант"  # Russian
]

## Generate a random soul name with era-appropriate title and names
static func generate_soul_name(era: int = -1) -> String:
	var first: String
	var last: String

	# Modern era allows mixed names (globalization)
	if era == 3:  # MODERN
		first = MODERN_FIRST_NAMES.pick_random()
		last = MODERN_LAST_NAMES.pick_random()
	else:
		# Historical eras: pick a civilization and keep names from same culture
		var civ_data = _get_random_civilization_names(era)
		first = civ_data.first_names.pick_random()
		last = civ_data.last_names.pick_random()

	# Get era-appropriate title
	var title = ""
	if era >= 0:
		var title_list = _get_era_titles(era)
		title = title_list.pick_random()

	if title != "":
		return "%s %s %s" % [title, first, last]
	else:
		return "%s %s" % [first, last]

## Get names from a random civilization within an era (keeps cultural consistency)
static func _get_random_civilization_names(era: int) -> Dictionary:
	match era:
		0:  # CLASSICAL
			return CLASSICAL_CIVILIZATIONS.pick_random()
		1:  # ANCIENT
			return ANCIENT_CIVILIZATIONS.pick_random()
		2:  # PREHISTORIC
			return PREHISTORIC_CIVILIZATIONS.pick_random()
		_:
			# Fallback: use modern (but allow mixing)
			return {"first_names": MODERN_FIRST_NAMES, "last_names": MODERN_LAST_NAMES}

## Get appropriate titles for an era
static func _get_era_titles(era: int) -> Array:
	match era:
		0: # CLASSICAL
			return CLASSICAL_TITLES
		1: # ANCIENT
			return ANCIENT_TITLES
		2: # PREHISTORIC
			return PREHISTORIC_TITLES
		3: # MODERN
			return MODERN_TITLES
		_:
			return ["", "", "", "", ""]  # Default: mostly no title
