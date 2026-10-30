/* Familles / sous-familles du catalogue — une ligne = fr|en|es|it|pt (voir i18n.js).
 * Les marques, diamètres (DN…) et références restent tels quels. */
(function(){
var TXT=`
Accessoires béton armé|Reinforced concrete accessories|Accesorios para hormigón armado|Accessori per cemento armato|Acessórios para betão armado
Adjuvants béton|Concrete admixtures|Aditivos para hormigón|Additivi per calcestruzzo|Adjuvantes para betão
Appareil scellement|Anchoring devices|Aparatos de sellado|Apparecchi di ancoraggio|Aparelhos de selagem
Armatures & Distanceurs|Reinforcement & Spacers|Armaduras y separadores|Armature e distanziatori|Armaduras e espaçadores
Aspiratrice & pompage|Suction & pumping|Aspiración y bombeo|Autospurgo e pompaggio|Aspiração e bombagem
Autre sécurité EPI|Other safety / PPE|Otra seguridad / EPI|Altra sicurezza / DPI|Outra segurança / EPI
Autre électroportatif|Other power tools|Otras herramientas eléctricas|Altri elettroutensili|Outras ferramentas elétricas
Bac rétention / citerne / bidon|Retention tray / tank / drum|Cubeta de retención / cisterna / bidón|Vasca di ritenzione / cisterna / fusto|Bacia de retenção / cisterna / bidão
Bois|Timber|Madera|Legno|Madeira
Bois & Coffrage|Timber & Formwork|Madera y encofrado|Legno e casseforme|Madeira e cofragem
Canalisations PE/HDPE|PE/HDPE pipework|Canalizaciones PE/HDPE|Canalizzazioni PE/HDPE|Canalizações PE/HDPE
Canalisations PP|PP pipework|Canalizaciones PP|Canalizzazioni PP|Canalizações PP
Canalisations PVC|PVC pipework|Canalizaciones PVC|Canalizzazioni PVC|Canalizações PVC
Canalisation|Pipework|Canalización|Canalizzazione|Canalização
Canalisations|Pipework|Canalizaciones|Canalizzazioni|Canalizações
Caniveau|Channel drain|Canaleta|Canaletta|Caleira
Chambres & Regards|Chambers & Manholes|Cámaras y pozos de registro|Camere e pozzetti|Câmaras e caixas de visita
Chauffage et ventilation|Heating and ventilation|Calefacción y ventilación|Riscaldamento e ventilazione|Aquecimento e ventilação
Chevalet|Trestle|Caballete|Cavalletto|Cavalete
Ciments & Bétons|Cements & Concretes|Cementos y hormigones|Cementi e calcestruzzi|Cimentos e betões
Coffrage|Formwork|Encofrado|Casseforme|Cofragem
Coffrage & Étaiement|Formwork & Propping|Encofrado y apuntalamiento|Casseforme e puntellamento|Cofragem e escoramento
Coffrage / accessoires|Formwork / accessories|Encofrado / accesorios|Casseforme / accessori|Cofragem / acessórios
Coffre et rangement|Chests and storage|Cofres y almacenaje|Cassette e contenitori|Caixas e arrumação
Colisage|Packaging|Embalaje|Imballaggio|Embalagem
Consommable|Consumables|Consumibles|Materiale di consumo|Consumíveis
Container outillage|Tool container|Contenedor de herramientas|Container utensili|Contentor de ferramentas
Cure & décoffrage|Curing & stripping|Curado y desencofrado|Stagionatura e disarmo|Cura e descofragem
Echelle|Ladder|Escalera|Scala|Escada
Electricité|Electricity|Electricidad|Elettricità|Eletricidade
Equipement gaz|Gas equipment|Equipo de gas|Attrezzatura a gas|Equipamento a gás
Fermeture de chantier|Site fencing|Cierre de obra|Chiusura del cantiere|Vedação de obra
Fixation|Fastening|Fijación|Fissaggio|Fixação
Fixations, outillage & consommables|Fasteners, tools & consumables|Fijaciones, herramientas y consumibles|Fissaggi, utensili e materiali di consumo|Fixações, ferramentas e consumíveis
Forage / démolition|Drilling / demolition|Perforación / demolición|Foratura / demolizione|Furação / demolição
Fournitures & Divers|Supplies & Miscellaneous|Suministros y varios|Forniture e varie|Fornecimentos e diversos
GEOTEXTILE|GEOTEXTILE|GEOTEXTIL|GEOTESSILE|GEOTÊXTIL
Géotextile|Geotextile|Geotextil|Geotessile|Geotêxtil
Gardes corps|Guardrails|Barandillas|Parapetti|Guarda-corpos
Granulats & Agrégats|Aggregates|Áridos y agregados|Aggregati e inerti|Agregados e inertes
Granulats & béton|Aggregates & concrete|Áridos y hormigón|Aggregati e calcestruzzo|Agregados e betão
Implantation mesure / traçage|Setting out / measuring / marking|Replanteo / medición / trazado|Tracciamento / misurazione / segnatura|Implantação / medição / marcação
Isolation|Insulation|Aislamiento|Isolamento|Isolamento
Isolation & Étanchéité|Insulation & Waterproofing|Aislamiento e impermeabilización|Isolamento e impermeabilizzazione|Isolamento e impermeabilização
Levage spécifique|Specific lifting|Elevación específica|Sollevamento specifico|Elevação específica
Lubrifiant et carburant Entretiens|Lubricants, fuel & maintenance|Lubricantes, combustible y mantenimiento|Lubrificanti, carburante e manutenzione|Lubrificantes, combustível e manutenção
Manutention|Handling|Manipulación|Movimentazione|Movimentação
Mastics & Colles|Sealants & Adhesives|Masillas y adhesivos|Sigillanti e colle|Mástiques e colas
Matériaux de construction|Building materials|Materiales de construcción|Materiali da costruzione|Materiais de construção
Matériel de levage|Lifting equipment|Material de elevación|Attrezzature di sollevamento|Material de elevação
Maçonnerie & Briques|Masonry & Bricks|Mampostería y ladrillos|Muratura e mattoni|Alvenaria e tijolos
Menuiserie|Carpentry|Carpintería|Falegnameria|Carpintaria
Mesure / Peson|Measuring / Weighing|Medición / Pesaje|Misura / Pesatura|Medição / Pesagem
Mobilier / électroménager|Furniture / appliances|Mobiliario / electrodomésticos|Arredi / elettrodomestici|Mobiliário / eletrodomésticos
Nettoyage entretiens|Cleaning & maintenance|Limpieza y mantenimiento|Pulizia e manutenzione|Limpeza e manutenção
Outillage manuel|Hand tools|Herramientas manuales|Utensili manuali|Ferramentas manuais
Outillage électroportatif|Power tools|Herramientas eléctricas|Elettroutensili|Ferramentas elétricas
Peinture et application|Paint and application|Pintura y aplicación|Pittura e applicazione|Pintura e aplicação
Perçage, burinage & découpe|Drilling, chiselling & cutting|Taladrado, cincelado y corte|Foratura, scalpellatura e taglio|Furação, cinzelagem e corte
Pharmacie / hygiène|Pharmacy / hygiene|Farmacia / higiene|Farmacia / igiene|Farmácia / higiene
Pompe à béton|Concrete pump|Bomba de hormigón|Pompa per calcestruzzo|Bomba de betão
Pompes à eau|Water pumps|Bombas de agua|Pompe per acqua|Bombas de água
Prestations de laboratoire|Laboratory services|Servicios de laboratorio|Prestazioni di laboratorio|Serviços de laboratório
Protection Câbles|Cable protection|Protección de cables|Protezione cavi|Proteção de cabos
Protection auditive|Hearing protection|Protección auditiva|Protezione dell'udito|Proteção auditiva
Protection de la tête|Head protection|Protección de la cabeza|Protezione del capo|Proteção da cabeça
Protection des mains|Hand protection|Protección de las manos|Protezione delle mani|Proteção das mãos
Protection des pieds|Foot protection|Protección de los pies|Protezione dei piedi|Proteção dos pés
Protection des yeux|Eye protection|Protección de los ojos|Protezione degli occhi|Proteção dos olhos
Protection incendie|Fire protection|Protección contra incendios|Protezione antincendio|Proteção contra incêndios
Protection respiratoire|Respiratory protection|Protección respiratoria|Protezione respiratoria|Proteção respiratória
Protection sur chantier|Site protection|Protección en obra|Protezione in cantiere|Proteção em obra
Protection travail en hauteur|Fall protection|Protección para trabajos en altura|Protezione per lavori in quota|Proteção para trabalhos em altura
Préfa-béton|Precast concrete|Prefabricados de hormigón|Prefabbricati in calcestruzzo|Pré-fabricados de betão
Publicité / objet de communication|Advertising / promotional items|Publicidad / objetos promocionales|Pubblicità / oggetti promozionali|Publicidade / objetos promocionais
Rabotage talochage et traitement de sol et mur|Planing, floating and floor & wall treatment|Cepillado, fratasado y tratamiento de suelos y paredes|Piallatura, frattazzatura e trattamento di pavimenti e pareti|Aplainamento, talochagem e tratamento de pavimentos e paredes
Réparation & scellement|Repair & sealing|Reparación y sellado|Riparazione e sigillatura|Reparação e selagem
Saturn S — étancheurs de passage|Saturn S — pipe-penetration seals|Saturn S — sellados de paso|Saturn S — sigillanti di passaggio|Saturn S — vedantes de passagem
Sciage / coupe|Sawing / cutting|Aserrado / corte|Segatura / taglio|Serragem / corte
Serrurerie|Locksmithing|Cerrajería|Serrature|Serralharia
Signalisation routière et panneaux|Road signs and panels|Señalización vial y paneles|Segnaletica stradale e pannelli|Sinalização rodoviária e painéis
Soudure|Welding|Soldadura|Saldatura|Soldadura
Toitures végétalisées|Green roofs|Cubiertas ajardinadas|Tetti verdi|Coberturas ajardinadas
Traitement eau|Water treatment|Tratamiento de agua|Trattamento dell'acqua|Tratamento de água
Tuyau alimentation eau / air|Water / air supply hose|Manguera de suministro de agua / aire|Tubo di alimentazione acqua / aria|Mangueira de alimentação de água / ar
Télécommunication - radio|Telecommunication - radio|Telecomunicación - radio|Telecomunicazioni - radio|Telecomunicações - rádio
Voirie & Aménagement|Roadworks & Landscaping|Viales y urbanización|Viabilità e sistemazioni|Vias e arranjos exteriores
Étanchéité|Waterproofing|Impermeabilización|Impermeabilizzazione|Impermeabilização
Étanchéité liquide|Liquid waterproofing|Impermeabilización líquida|Impermeabilizzazione liquida|Impermeabilização líquida
Absorbant|Absorbent|Absorbente|Assorbente|Absorvente
Accessoires|Accessories|Accesorios|Accessori|Acessórios
Accessoires PVC|PVC accessories|Accesorios PVC|Accessori PVC|Acessórios PVC
Accessoires aspirateur|Vacuum cleaner accessories|Accesorios de aspiradora|Accessori per aspirapolvere|Acessórios de aspirador
Accessoires de colisage|Packaging accessories|Accesorios de embalaje|Accessori per imballaggio|Acessórios de embalagem
Accessoires de montage|Mounting accessories|Accesorios de montaje|Accessori di montaggio|Acessórios de montagem
Accessoires ferblanterie|Sheet-metal accessories|Accesorios de hojalatería|Accessori per lattoneria|Acessórios de funilaria
Accessoires pompe|Pump accessories|Accesorios de bomba|Accessori per pompa|Acessórios de bomba
Accessoires pour chapes flottantes|Floating screed accessories|Accesorios para soleras flotantes|Accessori per massetti galleggianti|Acessórios para betonilhas flutuantes
Accessoires pour maçon|Bricklayer accessories|Accesorios para albañil|Accessori per muratore|Acessórios para pedreiro
Accessoires pour toitures plates|Flat roof accessories|Accesorios para cubiertas planas|Accessori per tetti piani|Acessórios para coberturas planas
Accessoires sciage / coupe|Sawing / cutting accessories|Accesorios de aserrado / corte|Accessori per segatura / taglio|Acessórios de serragem / corte
Accessoires toitures végétalisées|Green roof accessories|Accesorios para cubiertas ajardinadas|Accessori per tetti verdi|Acessórios para coberturas ajardinadas
Accessoires béton/mortiers|Concrete / mortar accessories|Accesorios para hormigón / morteros|Accessori per calcestruzzo / malte|Acessórios para betão / argamassas
Adaptateur|Adapter|Adaptador|Adattatore|Adaptador
Aménagement extérieur|Outdoor landscaping|Acondicionamiento exterior|Sistemazione esterna|Arranjo exterior
Anneaux de regard|Manhole rings|Anillos de pozo de registro|Anelli per pozzetti|Aros de caixa de visita
Antigel|Antifreeze|Anticongelante|Antigelo|Anticongelante
Armatures treillis|Mesh reinforcement|Armaduras de malla|Armature a rete|Armaduras de malha
Arrimage|Lashing|Estiba|Ancoraggio del carico|Amarração
Autre coffrage et accessoires|Other formwork and accessories|Otro encofrado y accesorios|Altre casseforme e accessori|Outra cofragem e acessórios
Autre colisage|Other packaging|Otro embalaje|Altro imballaggio|Outra embalagem
Autre fermeture de chantier|Other site fencing|Otro cierre de obra|Altra chiusura di cantiere|Outra vedação de obra
Autre fixation|Other fastening|Otra fijación|Altro fissaggio|Outra fixação
Autre garde corps|Other guardrails|Otras barandillas|Altri parapetti|Outros guarda-corpos
Autre implantation|Other setting out|Otro replanteo|Altro tracciamento|Outra implantação
Autre manutention|Other handling|Otra manipulación|Altra movimentazione|Outra movimentação
Autre matériel levage|Other lifting equipment|Otro material de elevación|Altre attrezzature di sollevamento|Outro material de elevação
Autre mobilier|Other furniture|Otro mobiliario|Altri arredi|Outro mobiliário
Autre outillage manuel|Other hand tools|Otras herramientas manuales|Altri utensili manuali|Outras ferramentas manuais
Autre protection de la tête|Other head protection|Otra protección de la cabeza|Altra protezione del capo|Outra proteção da cabeça
Autre protection des mains|Other hand protection|Otra protección de las manos|Altra protezione delle mani|Outra proteção das mãos
Autre protection des pieds|Other foot protection|Otra protección de los pies|Altra protezione dei piedi|Outra proteção dos pés
Autre protection des yeux|Other eye protection|Otra protección de los ojos|Altra protezione degli occhi|Outra proteção dos olhos
Autre protection respiratoire|Other respiratory protection|Otra protección respiratoria|Altra protezione respiratoria|Outra proteção respiratória
Autre protection travail en hauteur|Other fall protection|Otra protección para trabajos en altura|Altra protezione per lavori in quota|Outra proteção para trabalhos em altura
Autre rangement|Other storage|Otro almacenaje|Altro stoccaggio|Outra arrumação
Autre équipement levage spécifique|Other specific lifting equipment|Otro equipo de elevación específico|Altre attrezzature di sollevamento specifico|Outro equipamento de elevação específico
Autre équipement routier|Other road equipment|Otro equipo vial|Altre attrezzature stradali|Outro equipamento rodoviário
Autres produits PE/HDPE|Other PE/HDPE products|Otros productos PE/HDPE|Altri prodotti PE/HDPE|Outros produtos PE/HDPE
Autres produits Protection Câbles|Other cable protection products|Otros productos de protección de cables|Altri prodotti per protezione cavi|Outros produtos de proteção de cabos
Autres produits caniveaux|Other channel drain products|Otros productos de canaletas|Altri prodotti per canalette|Outros produtos de caleiras
Autres produits préfa béton|Other precast concrete products|Otros productos prefabricados de hormigón|Altri prodotti prefabbricati in calcestruzzo|Outros produtos pré-fabricados de betão
Bac rétention|Retention tray|Cubeta de retención|Vasca di ritenzione|Bacia de retenção
Bidon et jerrican et distribution|Drums, jerrycans & dispensing|Bidones, garrafas y distribución|Fusti, taniche e distribuzione|Bidões, jerricãs e distribuição
Bordures|Kerbs|Bordillos|Cordoli|Lancis
Bordures & pavés|Kerbs & paving stones|Bordillos y adoquines|Cordoli e masselli|Lancis e paralelepípedos
Bordures granit|Granite kerbs|Bordillos de granito|Cordoli in granito|Lancis de granito
Bordures îlot & planelles d'écoulement|Island kerbs & drainage flags|Bordillos de isleta y losetas de desagüe|Cordoli spartitraffico e lastre di scolo|Lancis de ilhéu e lajetas de escoamento
Bottes PVC|PVC boots|Botas de PVC|Stivali in PVC|Botas de PVC
Bottes PVC fourrées|Lined PVC boots|Botas de PVC forradas|Stivali in PVC foderati|Botas de PVC forradas
Bouchons|Plugs|Tapones|Tappi|Tampões
Burins|Chisels|Cinceles|Scalpelli|Escopros
Béton|Concrete|Hormigón|Calcestruzzo|Betão
Béton classé|Graded concrete|Hormigón clasificado|Calcestruzzo classificato|Betão classificado
Béton recyclé|Recycled concrete|Hormigón reciclado|Calcestruzzo riciclato|Betão reciclado
Cabane à plan|Plan hut|Caseta de planos|Baracca per planimetrie|Barraca de planos
Cadre & couvercle en béton|Concrete frame & cover|Marco y tapa de hormigón|Telaio e coperchio in calcestruzzo|Aro e tampa de betão
Caniveaux de drainage|Drainage channels|Canaletas de drenaje|Canalette di drenaggio|Caleiras de drenagem
Carrelets|Battens|Listones|Travetti|Barrotes
Casque|Helmet|Casco|Casco|Capacete
Casque et bouchon|Helmet and earplug|Casco y tapón|Casco e tappo|Capacete e tampão
Chaussure de sécurité|Safety shoe|Calzado de seguridad|Scarpa di sicurezza|Calçado de segurança
Chambres|Chambers|Cámaras|Camere|Câmaras
Ciments en sac|Bagged cement|Cementos en saco|Cementi in sacco|Cimentos em saco
Clapets|Valves|Válvulas antirretorno|Valvole di non ritorno|Válvulas de retenção
Clavette et tendeur|Cotter pin and tensioner|Chaveta y tensor|Chiavetta e tenditore|Chaveta e tensor
Clous|Nails|Clavos|Chiodi|Pregos
Clôture et accessoires|Fencing and accessories|Vallado y accesorios|Recinzione e accessori|Vedação e acessórios
Coffre bancheur|Shuttering box|Cofre de encofrador|Cassetta per casserista|Caixa de cofrador
Coffre à outil|Tool chest|Caja de herramientas|Cassetta degli attrezzi|Caixa de ferramentas
Colle|Glue|Cola|Colla|Cola
Colles|Adhesives|Adhesivos|Colle|Colas
Compresseur Metabo|Metabo compressor|Compresor Metabo|Compressore Metabo|Compressor Metabo
Conduite béton|Concrete line|Tubería de hormigón|Tubazione per calcestruzzo|Conduta de betão
Consommable accessoires|Consumable accessories|Accesorios consumibles|Accessori di consumo|Acessórios consumíveis
Consommable accessoires et entretiens|Consumable accessories & maintenance|Accesorios consumibles y mantenimiento|Accessori di consumo e manutenzione|Acessórios consumíveis e manutenção
Consommable aspirateur|Vacuum cleaner consumables|Consumibles de aspiradora|Materiale di consumo per aspirapolvere|Consumíveis de aspirador
Consommable coffrage|Formwork consumables|Consumibles de encofrado|Materiale di consumo per casseforme|Consumíveis de cofragem
Consommable machine à outil|Machine tool consumables|Consumibles de máquina herramienta|Materiale di consumo per macchine utensili|Consumíveis de máquina-ferramenta
Consommables Soudure|Welding consumables|Consumibles de soldadura|Materiale di consumo per saldatura|Consumíveis de soldadura
Consommables découpe bois|Wood-cutting consumables|Consumibles de corte de madera|Materiale di consumo per taglio legno|Consumíveis de corte de madeira
Contenant (Brouette gamatte sceau…)|Containers (wheelbarrow, bucket…)|Recipientes (carretilla, cubo…)|Contenitori (carriola, secchio…)|Recipientes (carrinho de mão, balde…)
Corde et bande d'étanchéité|Sealing cord and tape|Cuerda y cinta de sellado|Corda e nastro di tenuta|Corda e fita de vedação
Coudes|Bends|Codos|Curve|Curvas
Coupant (Coupe boulons tenaille scie…)|Cutting (bolt cutter, pliers, saw…)|Corte (cortapernos, tenaza, sierra…)|Taglio (tronchese, pinza, sega…)|Corte (corta-parafusos, alicate, serra…)
Crépi|Roughcast|Revoque|Intonaco|Reboco
Cuissardes|Waders|Vadeadores|Stivaloni|Botas de pesca
Dalles|Slabs|Losas|Lastre|Lajes
Dalles standard|Standard slabs|Losas estándar|Lastre standard|Lajes standard
Disques|Discs|Discos|Dischi|Discos
Disques à tronçonner|Cutting discs|Discos de corte|Dischi da taglio|Discos de corte
Distanceurs|Spacers|Separadores|Distanziatori|Espaçadores
Divers|Miscellaneous|Varios|Varie|Diversos
Décoffrants|Release agents|Desencofrantes|Disarmanti|Descofrantes
Démolition & décharge|Demolition & disposal|Demolición y vertedero|Demolizione e discarica|Demolição e descarga
Echelles CORSCAL|CORSCAL ladders|Escaleras CORSCAL|Scale CORSCAL|Escadas CORSCAL
Eclairage|Lighting|Iluminación|Illuminazione|Iluminação
Electroménager|Appliances|Electrodomésticos|Elettrodomestici|Eletrodomésticos
Electroportatif|Power tools|Herramientas eléctricas|Elettroutensili|Ferramentas elétricas
Elingue chaine|Chain sling|Eslinga de cadena|Brache a catena|Lingas de corrente
Elingue textile|Textile sling|Eslinga textil|Brache tessile|Lingas têxteis
Embranchements|Branches|Derivaciones|Derivazioni|Ramais
Escabeau et marche pied|Step ladder and step stool|Escalera de tijera y taburete|Scaleo e sgabello|Escadote e banco
Essais béton durci|Hardened concrete tests|Ensayos de hormigón endurecido|Prove su calcestruzzo indurito|Ensaios de betão endurecido
Essais béton frais|Fresh concrete tests|Ensayos de hormigón fresco|Prove su calcestruzzo fresco|Ensaios de betão fresco
Essais grave béton|Concrete gravel tests|Ensayos de grava y hormigón|Prove su ghiaia e calcestruzzo|Ensaios de brita e betão
Extincteur|Fire extinguisher|Extintor|Estintore|Extintor
Fermeture et cadenas|Locks and padlocks|Cierre y candados|Chiusura e lucchetti|Fecho e cadeados
Feuille de poncage|Sanding sheet|Hoja de lijado|Foglio abrasivo|Folha de lixa
Finition (éponge pinceau bouchardeur manuel…)|Finishing (sponge, brush, manual bush hammer…)|Acabado (esponja, pincel, abujardador manual…)|Finitura (spugna, pennello, bocciarda manuale…)|Acabamento (esponja, pincel, escafilador manual…)
Fond de regard CENTUB|CENTUB manhole base|Fondo de pozo CENTUB|Fondo pozzetto CENTUB|Fundo de caixa de visita CENTUB
Fond de regard CRENO/CREMA/KERES|CRENO/CREMA/KERES manhole base|Fondo de pozo CRENO/CREMA/KERES|Fondo pozzetto CRENO/CREMA/KERES|Fundo de caixa de visita CRENO/CREMA/KERES
Forets|Drill bits|Brocas|Punte|Brocas
Forfaits aspiratrice|Suction truck flat rates|Tarifas fijas de aspiradora|Forfait autospurgo|Forfaits de aspiradora
Frappant (Marteau masse massette…)|Striking (hammer, sledgehammer, mallet…)|Percusión (martillo, maza, mazo…)|Percussione (martello, mazza, mazzetta…)|Percussão (martelo, marreta, maceta…)
Gaine pour ventilateur|Fan duct|Manga para ventilador|Condotto per ventilatore|Conduta para ventilador
Gant cuir|Leather glove|Guante de cuero|Guanto in pelle|Luva de couro
Gant de manutention fin / maçon|Thin handling / mason glove|Guante de manipulación fino / albañil|Guanto da movimentazione sottile / muratore|Luva de manuseamento fina / pedreiro
Gant de manutention fourré hivers|Lined winter handling glove|Guante de manipulación forrado de invierno|Guanto da movimentazione foderato invernale|Luva de manuseamento forrada de inverno
Gant de manutention épais / maçon|Thick handling / mason glove|Guante de manipulación grueso / albañil|Guanto da movimentazione spesso / muratore|Luva de manuseamento grossa / pedreiro
Gants résistants aux liquides|Liquid-resistant gloves|Guantes resistentes a líquidos|Guanti resistenti ai liquidi|Luvas resistentes a líquidos
Gravier|Gravel|Grava|Ghiaia|Gravilha
Grille caillebotis pour saut de loup|Grating for light well|Rejilla para patio inglés|Griglia per bocca di lupo|Grelha para poço de luz
Grilles caillebotis & fixations|Gratings & fixings|Rejillas y fijaciones|Griglie e fissaggi|Grelhas e fixações
Géotextile HGC Premium|HGC Premium geotextile|Geotextil HGC Premium|Geotessile HGC Premium|Geotêxtil HGC Premium
Géotextile non tissés|Non-woven geotextile|Geotextil no tejido|Geotessile non tessuto|Geotêxtil não tecido
Géotextiles non-tissés HGC Premium et Sytec|HGC Premium and Sytec non-woven geotextiles|Geotextiles no tejidos HGC Premium y Sytec|Geotessili non tessuti HGC Premium e Sytec|Geotêxteis não tecidos HGC Premium e Sytec
Gand anti vibration|Anti-vibration glove|Guante antivibración|Guanto antivibrazione|Luva antivibração
Huile graisse pour engin|Oil & grease for machinery|Aceite y grasa para maquinaria|Olio e grasso per macchine|Óleo e massa lubrificante para máquinas
Joints|Gaskets|Juntas|Guarnizioni|Juntas
Lambourdes|Joists|Rastreles|Listelli|Barrotes
Lame|Blade|Hoja|Lama|Lâmina
Latte / support|Lath / support|Listón / soporte|Listello / supporto|Ripa / suporte
Ligatures|Tie wires|Ataduras|Legature|Atilhos
Ligatures à béton|Concrete tie wires|Ataduras para hormigón|Legature per calcestruzzo|Atilhos para betão
Linteaux|Lintels|Dinteles|Architravi|Padieiras
Lisser (Platoir règle truelle râteau…)|Smoothing (float, screed rule, trowel, rake…)|Alisado (llana, regla, paleta, rastrillo…)|Lisciatura (frattazzo, staggia, cazzuola, rastrello…)|Alisamento (talocha, régua, colher, ancinho…)
Luminaire|Light fitting|Luminaria|Lampada|Luminária
Lunettes|Glasses|Gafas|Occhiali|Óculos
Manchons|Couplings|Manguitos|Manicotti|Mangas
Manille|Shackle|Grillete|Grillo|Manilha
Manille de paplanche|Sheet-pile shackle|Grillete de tablestaca|Grillo per palancola|Manilha de estaca-prancha
Masque|Mask|Mascarilla|Maschera|Máscara
Masques anti poussière réutilisable|Reusable dust masks|Mascarillas antipolvo reutilizables|Maschere antipolvere riutilizzabili|Máscaras antipoeira reutilizáveis
Masques anti poussière usage unique|Disposable dust masks|Mascarillas antipolvo de un solo uso|Maschere antipolvere monouso|Máscaras antipoeira descartáveis
Mastics|Sealants|Masillas|Sigillanti|Mástiques
Matériaux de construction|Building materials|Materiales de construcción|Materiali da costruzione|Materiais de construção
Meules boisseaux|Cup wheels|Muelas de copa|Mole a tazza|Mós de taça
Meules-boisseaux diamantées|Diamond cup wheels|Muelas de copa diamantadas|Mole a tazza diamantate|Mós de taça diamantadas
Mobilier|Furniture|Mobiliario|Arredi|Mobiliário
Mortiers|Mortars|Morteros|Malte|Argamassas
Mortiers de réparation|Repair mortars|Morteros de reparación|Malte da riparazione|Argamassas de reparação
Mortiers de scellement (Grout)|Grouting mortars (Grout)|Morteros de sellado (Grout)|Malte di ancoraggio (Grout)|Argamassas de selagem (Grout)
Mousse expansive|Expanding foam|Espuma expansiva|Schiuma espansiva|Espuma expansiva
Murs, équerres & blocs|Walls, brackets & blocks|Muros, escuadras y bloques|Muri, squadre e blocchi|Muros, esquadros e blocos
Métal déployé|Expanded metal|Metal desplegado|Metallo stirato|Metal expandido
Nettoyer (Grattoir raclette…)|Cleaning (scraper, squeegee…)|Limpieza (rasqueta, rasqueta de goma…)|Pulizia (raschietto, racla…)|Limpeza (raspador, rodo…)
Outil levier (barre à mine pied de biche…)|Leverage tools (crowbar, pry bar…)|Herramienta de palanca (barra de mina, pie de cabra…)|Utensile a leva (palanchino, piede di porco…)|Ferramenta de alavanca (alavanca, pé-de-cabra…)
Outil pose élément préfa béton|Precast concrete laying tool|Herramienta de colocación de prefabricados de hormigón|Utensile per posa elementi prefabbricati|Ferramenta de assentamento de pré-fabricados
Ouverture de nettoyage|Cleaning opening|Abertura de limpieza|Apertura di pulizia|Abertura de limpeza
Paniers|Baskets|Cestas|Ceste|Cestos
Panneau / affichage interne chantier|Panel / internal site display|Panel / cartelería interna de obra|Pannello / affissione interna di cantiere|Painel / afixação interna de obra
Panneaux|Panels|Paneles|Pannelli|Painéis
Panneaux OSB 3|OSB 3 panels|Paneles OSB 3|Pannelli OSB 3|Painéis OSB 3
Panneaux jaunes|Yellow panels|Paneles amarillos|Pannelli gialli|Painéis amarelos
Panneaux routier|Road signs|Señales de carretera|Cartelli stradali|Sinais rodoviários
Pavés & dalles|Paving stones & slabs|Adoquines y losas|Masselli e lastre|Paralelepípedos e lajes
Peinture|Paint|Pintura|Pittura|Tinta
Perforateur Bosch|Bosch rotary hammer|Martillo perforador Bosch|Perforatore Bosch|Martelo perfurador Bosch
Pistolet|Gun|Pistola|Pistola|Pistola
Pistolet à clou|Nail gun|Pistola de clavos|Chiodatrice|Pistola de pregos
Planches de coffrage|Formwork boards|Tablas de encofrado|Tavole per casseforme|Tábuas de cofragem
Plaques|Plates|Placas|Lastre|Placas
Plateau bois C24|C24 timber plank|Tablón de madera C24|Tavolone in legno C24|Prancha de madeira C24
Plots|Blocks|Tacos|Tasselli|Calços
Plus-value & façonnage CENTUB|CENTUB surcharge & fabrication|Sobreprecio y fabricación CENTUB|Maggiorazione e lavorazione CENTUB|Mais-valia e fabrico CENTUB
Poubelle et accessoires|Bin and accessories|Papelera y accesorios|Cestino e accessori|Caixote do lixo e acessórios
Poutrelles H20|H20 beams|Vigas H20|Travi H20|Vigas H20
Prestations à l'heure|Hourly services|Servicios por hora|Prestazioni a ore|Serviços à hora
Produit de pharmacie / hygiène|Pharmacy / hygiene product|Producto de farmacia / higiene|Prodotto di farmacia / igiene|Produto de farmácia / higiene
Produits de cure|Curing products|Productos de curado|Prodotti per la stagionatura|Produtos de cura
Prolongateur / rallonge Td / multi prise|Extension lead / multi-socket|Alargador / regleta multitoma|Prolunga / multipresa|Extensão / ficha múltipla
Protection / signalisation de sol|Floor protection / marking|Protección / señalización de suelo|Protezione / segnaletica a pavimento|Proteção / sinalização de pavimento
Protection armature|Reinforcement protection|Protección de armaduras|Protezione armature|Proteção de armaduras
Puits de drainage|Drainage wells|Pozos de drenaje|Pozzi di drenaggio|Poços de drenagem
Quincaillerie|Hardware|Ferretería|Ferramenta|Ferragens
Raccord PVC ciment|PVC cement fitting|Racor PVC cemento|Raccordo PVC cemento|União PVC cimento
Raccords|Fittings|Racores|Raccordi|Uniões
Recycling|Recycling|Reciclaje|Riciclaggio|Reciclagem
Ruban adhésif|Adhesive tape|Cinta adhesiva|Nastro adesivo|Fita adesiva
Réductions|Reducers|Reducciones|Riduzioni|Reduções
Résine|Resin|Resina|Resina|Resina
Sable|Sand|Arena|Sabbia|Areia
Sables & graves|Sands & gravels|Arenas y gravas|Sabbie e ghiaie|Areias e cascalhos
Sac aspirateur|Vacuum cleaner bag|Bolsa de aspiradora|Sacchetto per aspirapolvere|Saco de aspirador
Saut de loup|Light well|Patio inglés|Bocca di lupo|Poço de luz
Sauts-de-loup (éléments standard)|Light wells (standard elements)|Patios ingleses (elementos estándar)|Bocche di lupo (elementi standard)|Poços de luz (elementos standard)
Scie cloche|Hole saw|Sierra de corona|Sega a tazza|Serra de copo
Serre joint|Clamp|Sargento|Morsetto|Grampo
Silicones|Silicones|Siliconas|Siliconi|Silicones
Spary de marquage|Marking spray|Spray de marcaje|Spray di marcatura|Spray de marcação
Superplastifiants ViscoCrete|ViscoCrete superplasticizers|Superplastificantes ViscoCrete|Superfluidificanti ViscoCrete|Superplastificantes ViscoCrete
Système grillagé|Mesh system|Sistema de malla|Sistema a rete|Sistema de rede
Système à planche|Board system|Sistema de tablas|Sistema a tavole|Sistema de tábuas
Système à tube / lisse|Tube / rail system|Sistema de tubo / barra|Sistema a tubo / corrente|Sistema de tubo / guarda
Tampon d'ancrage|Anchor plug|Tapón de anclaje|Tassello di ancoraggio|Tampão de ancoragem
Tampon d'isolation|Insulation plug|Tapón de aislamiento|Tassello isolante|Tampão de isolamento
Tampon à clouer|Nail-in plug|Tapón de clavar|Tassello da chiodare|Tampão de pregar
Taquets béton|Concrete cleats|Tacos de hormigón|Tasselli per calcestruzzo|Calços de betão
Terrassement (Pelle pioche…)|Earthworks (shovel, pickaxe…)|Movimiento de tierras (pala, pico…)|Movimento terra (pala, piccone…)|Terraplenagem (pá, picareta…)
Toitures végétalisées|Green roofs|Cubiertas ajardinadas|Tetti verdi|Coberturas ajardinadas
Tubes de protection|Protection tubes|Tubos de protección|Tubi di protezione|Tubos de proteção
Tuyau / accessoire air|Air hose / accessory|Manguera / accesorio de aire|Tubo / accessorio aria|Mangueira / acessório de ar
Tuyau / accessoire eau|Water hose / accessory|Manguera / accesorio de agua|Tubo / accessorio acqua|Mangueira / acessório de água
Tuyau compact drainage|Compact drainage pipe|Tubo compacto de drenaje|Tubo compatto di drenaggio|Tubo compacto de drenagem
Tuyau de drainage|Drainage pipe|Tubo de drenaje|Tubo di drenaggio|Tubo de drenagem
Tuyaux|Pipes|Tubos|Tubi|Tubos
Tuyaux & bordures béton|Concrete pipes & kerbs|Tubos y bordillos de hormigón|Tubi e cordoli in calcestruzzo|Tubos e lancis de betão
Tuyaux CR0.5 (à bétonner)|CR0.5 pipes (to be concreted)|Tubos CR0.5 (a hormigonar)|Tubi CR0.5 (da betonare)|Tubos CR0.5 (a betonar)
Tuyaux annelés|Corrugated pipes|Tubos corrugados|Tubi corrugati|Tubos anelados
Tuyaux béton armé (DN 200+)|Reinforced concrete pipes (DN 200+)|Tubos de hormigón armado (DN 200+)|Tubi in cemento armato (DN 200+)|Tubos de betão armado (DN 200+)
Tuyaux compact standard|Standard compact pipes|Tubos compactos estándar|Tubi compatti standard|Tubos compactos standard
Tuyaux de drainage|Drainage pipes|Tubos de drenaje|Tubi di drenaggio|Tubos de drenagem
Tuyaux lisses|Smooth pipes|Tubos lisos|Tubi lisci|Tubos lisos
Tuyaux manchonnés|Socketed pipes|Tubos con manguito|Tubi con bicchiere|Tubos com manga
Tuyaux structurés standard|Standard structured pipes|Tubos estructurados estándar|Tubi strutturati standard|Tubos estruturados standard
Tuyaux-cônes standard|Standard pipe cones|Tubos-cono estándar|Tubi-coni standard|Tubos-cone standard
Ventilateur élec 220V|220V electric fan|Ventilador eléctrico 220V|Ventilatore elettrico 220V|Ventilador elétrico 220V
Visserie|Screws & bolts|Tornillería|Viteria|Parafusaria
Voirie|Roadworks|Viales|Viabilità|Vias
Étanchéité synthétique liquide - Outillage|Liquid synthetic waterproofing - Tooling|Impermeabilización sintética líquida - Herramientas|Impermeabilizzazione sintetica liquida - Attrezzi|Impermeabilização sintética líquida - Ferramentas
Étanchéité synthétique liquide 2K|2K liquid synthetic waterproofing|Impermeabilización sintética líquida 2K|Impermeabilizzazione sintetica liquida 2K|Impermeabilização sintética líquida 2K
Accessoires perforateur divers|Miscellaneous rotary hammer accessories|Accesorios varios de martillo perforador|Accessori vari per perforatore|Acessórios diversos de martelo perfurador
Accessoires marteau piqueur pneumatique|Pneumatic breaker accessories|Accesorios de martillo neumático|Accessori per martello pneumatico|Acessórios de martelo pneumático
Accessoires bouchardeur pneumatique|Pneumatic bush hammer accessories|Accesorios de abujardadora neumática|Accessori per bocciarda pneumatica|Acessórios de escafilador pneumático
Accessoires traitement sol et mur|Floor & wall treatment accessories|Accesorios de tratamiento de suelos y paredes|Accessori per trattamento pavimenti e pareti|Acessórios de tratamento de pavimentos e paredes
Accessoires talkie walkie|Walkie-talkie accessories|Accesorios de walkie-talkie|Accessori per ricetrasmittente|Acessórios de walkie-talkie
Accessoires tire fort|Come-along accessories|Accesorios de tirfor|Accessori per tirfor|Acessórios de tirfor
Batterie Bosch|Bosch battery|Batería Bosch|Batteria Bosch|Bateria Bosch
Echelle|Ladder|Escalera|Scala|Escada
Bouteroue|Wheel guard|Guardarruedas|Paraurti|Guarda-rodas
Laser Bosch|Bosch laser|Láser Bosch|Laser Bosch|Laser Bosch
Peson|Weighing scale|Dinamómetro|Dinamometro|Dinamómetro
Quincaillerie|Hardware|Ferretería|Ferramenta|Ferragens
Tuyaux CENTUB-Röser|CENTUB-Röser pipes|Tubos CENTUB-Röser|Tubi CENTUB-Röser|Tubos CENTUB-Röser
Tuyaux béton|Concrete pipes|Tubos de hormigón|Tubi in calcestruzzo|Tubos de betão
Grille caillebotis|Grating|Rejilla|Griglia|Grelha
Laine|Wool|Lana|Lana|Lã
Contreplaqué|Plywood|Contrachapado|Compensato|Contraplacado
Panneaux isolants|Insulation boards|Paneles aislantes|Pannelli isolanti|Painéis isolantes
Maçonnerie|Masonry|Mampostería|Muratura|Alvenaria
Pavés|Paving stones|Adoquines|Masselli|Paralelepípedos
Caniveaux|Channel drains|Canaletas|Canalette|Caleiras
Armatures|Reinforcement|Armaduras|Armature|Armaduras
Briques|Bricks|Ladrillos|Mattoni|Tijolos
Mortiers|Mortars|Morteros|Malte|Argamassas
Géotextiles|Geotextiles|Geotextiles|Geotessili|Geotêxteis
Planches|Boards|Tablas|Tavole|Tábuas
Panneaux|Panels|Paneles|Pannelli|Painéis
Dalles|Slabs|Losas|Lastre|Lajes
Maçonnerie & Briques|Masonry & Bricks|Mampostería y ladrillos|Muratura e mattoni|Alvenaria e tijolos
Plateau bois C24|C24 timber plank|Tablón de madera C24|Tavolone in legno C24|Prancha de madeira C24
`;
var E=[];
TXT.split('\n').forEach(function(l){var r=l.split('|'); if(r.length===5) E.push(r);});
var R=window.I18N_ROWS=window.I18N_ROWS||{E:[],F:[],P:[]};
R.E=R.E.concat(E);
})();
