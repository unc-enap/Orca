// update 2013-01-03 -tb-


#define	_version_OPERA	3.0

#include <stdint.h>  //for uint32_t etc.


// le 5 decembre je change le status : un mot de plus au debut  --
//  et  je rajoute le mode d'acquisition  BBv21  soit BBv2 avec sortie 4 valeurs, F-E,A,B,E+F et status en mot4 (dans E+F)
//  le 22 fevrier 2010  je rajoute le mode d'acquisition  BBv2_comp  


//-------------------------------------------------------------------------------------------------------
//--------------------    nouvelle version, pour EDW  1 ou 2 BB par carte OPERA  ou ADC simple ----------
//--------------------				avec lecture du temps donne par le repartiteur		----------------	
//-------------------------------------------------------------------------------------------------------

//---------------  definitions generales		------------------------------------------------------------------------------------------------

#define	 int4	int32_t

#if 0
#ifdef  __INT_MAX__
#if __INT_MAX__ == 2147483647			// on est dans une machine ou les entiers int  font deja 32 bit (systeme 10.6 par exemple)  il ne faut pas prendre les int32_t
#define	 int4	int
#else
#define	 int4	int32_t
#endif

#else		//  ifndef   __INT_MAX__    comme par exemple dans la carte opera
#define	 int4	int32_t
#endif
#endif


//#define	uint4	unsigned int4
#define	uint4	uint32_t




#define _mot_synchro			12567	// code de synchronisation (idem ecritdata.tdf)  utilise pour la reconnaissance de synchro dans les data
//DEBUG -tb-: _mot_synchro			12567	is 0x3117
#define _maxi_nb_bolo			2		//  maximum 2 bolos par carte OPERA
#define _maxi_nb_mots_lecture	12		//  Nombre maxi de mots de 32 bit par echantillon (2 mots de 32 bit pour 1 boite BBv1)
#define _nb_data_trame_udp		360		//  longueur standard des trames udp : ca fait (360+3) * 4 = 1452 octets
//#define _nb_data_trame_udp		352		//  parceque ca doit etre divisible par 16 pour le compresseur
						//  longueur standard des trames udp : ca fait (352+1) * 4 = 1412 octets





/*
---------------------------------------------------------------------------------------------------------
----------------------    Branchement des boites OPERA           -----------------
---------------------------------------------------------------------------------------------------------
premiere boite bolo :		Horloge: TX1		Commande: TX2		Data: RX1
deuxieme boite bolo :		Horloge: TX3		Commande: TX4		Data: RX2

Pour synchroniser le rack OPERA, il faut utiliser une carte en synchro:
	il faut lui envoyer		
			soit			- l'horloge SuperCluzel sur RX1
							- la commande  SuperCluzel sur RX2
			soit			- une horloge biphase en RX1
On programme alors cette boite avec		code_acqui	=  code_acqui_synchro
											masque_BB	= 1
											code_synchro = 14  (2+4+8 signifie 100000 points et horloge esclave temps et synchro)
	Elle sera programme automatiquement si on la lance avec  ./cew -r
	Cette boite sort alors un signal biphase de synchro sur le fond de pqnier et sur ses 2 sorties TX1, TX2

	Pour synchroniser alors une boite OPERA, il suffit de lui envoyer le signal de la boite repartiteur sur RX3
	Il faut alors la programmer avec		code_acqui	=  code_acqui_BB1
											masque_BB	= _masque_BB(nb1,nb2) ou nb1 et nb2 vaut 0 ou 2 
											code_synchro = 14  (2+4+8 signifie 100000 points et horloge esclave temps et synchro)
	Elle sera programmee automatiquement pour une boite BBV1 si on lance  ./cew -b

---------------------------------------------------------------------------------------------------------
----------------------    dans le circuit programmable de la carte OPERA -----------------
---------------------------------------------------------------------------------------------------------

-- A partir de la frequence horloge (nominal 6 MHz mais variable de 0.1 a 20 MHz)
-  pour boite bolo EDW  BB1  je divise par 60 pour faire un echantillonage
-  en mode code_acqui_synchro je divise par 60 = pour etre synchrone avec SuperCluzel BBV1
-  pour BB1 avec moyennage par 4 je divise par 60*4 = 240 : 4 mesures dans un echantillon
-  pour un ADC simple en mode code_acqui_ADC_moy2, je divise par 9* 4 = 36
					9 parceque j'utilise l'horloge double pour la conversion
					4 parceque je moyenne les mots par 2 et je mets 2 moyennes dans un mot de 32bit, soit 4 mesures
--  
--  Je fabrique alors un echantillon de mesure. C'est a cette frequence que j'envoie les donnees dans la fifo
-- les donnees de chaque echantillons sont reparties sur nb_mots  de 32 bit avant d'etre envoyees sur la fifo de la carte OPERA
--  pour les boites BBv1, on a 2 mots de 32bit, le premier contient les 2 premieres voies et le second la troisieme voie
--  si l'on a 2 boites BBv1, on a 4 mots de 32bit par echantillon
--  en mode code_acqui_synchro on a 1 mot de 32bit par echantillon
--  Nb_synchro est le nombre d'echantillons separant deux synchro principales.
--  dans une BBv1, ce doit etre le produit  div2*div3
--  attention, en moyennage par 4, on a 4 mesures dans un echantillon et on doit avoir div2*div3 = 4 * Nb_synchro

--  en fonctionnement nominal Nb_synchro =  20160  (nombre divisible par beaucoups de nombres )
--  pour fonctionnement esclave des supercluzel, je dois compter Nb_synchro = 100 000 0

--  A chaque synchro, le FPGA intercale dans le flux de data de la fifo,  3 mots de 32 bit contenant
--	un mot synchro		(CONSTANT  _mot_synchro = 12567; )  pour resynchroniser
--	le temps		incremente de 1 Ì°‰¥ùÌ­å¡Ì°å´Ì°‰¥ÏÌ°‰¥ùÌ­å¢Ì¢‰ÅÃ‰ÃûÌ­å´Ì­å¢Ì¢‰Å´å¢Ì°å£Ì°‰¥ùÌ­å¡Ì¢‰ÅÃ‰ÃûÌ­å´Ì°å£Ì°‰¥ùÌ­å¢Ì¢‰ÅÃ‰ÃûÌ­å´Ì­å¢Ì°å´Ì°‰³¢Ì°‰¥ùÌ°âÌ°å¬Ì°åÈÌ°‰¥ùÌ­å¡Ì°å´Ì°‰¥ÏÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì°ë©Ì°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­åÂÌ°‰¥ùÌ­å¢Ì¢‰ÅÃ‰ÃûÌ­å´Ì­å¢Ì°å´Ì¶‰¥¢Ì°‰¥ùÌ­å¡Ì°å´Ì°‰¥ÏÌ°‰¥ùÌ­å¢Ì¢‰ÅÃ‰ÃûÌ­å´Ì­å¢Ì¢‰Å´å¢Ì°å£Ì°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­åÂÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­å¢Ì°‰¥ùÌ­å¡Ì°å´Ì°‰¥ÏÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­å¢Ì°‰¥ùÌ­å¡Ì¢‰ÅÃ‰ÃûÌ­å´Ì°å£Ì°‰¥ùÌ­å¼Ì¢‰ÅÃ‰ÃûÌ­å´Ì°åÈÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­å¢Ì°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­åÂÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­å¢Ì°‰¥ùÌ­å¡Ì°å´Ì°‰¥ÏÌ°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì°ë©Ì°‰¥ùÌ¢‰¥¢‰¥õÌ°å´Ì­åÂÌ°‰¥ùÌ­å¡Ì°å¬Ì¢‰¥¢åÁ chaque toutdebut (cela fait un maxi de 4 * 10e9 coups a 5 Hz soit environ 25 ans)
--	un code d'acquisition 	forme de 1 octets code_acqui, un octet masque_BB  un octet nb_mots  et un octet code_synchro

--  ensuite, le flux de data comprend  ( nb_mots * Nb_synchro )  mots de 32 bit avant la synchro suivante


************************************************************************************************************************
**********************																			**********************
**********************    Description des trames UDP  emises sur le reseau par la carte OPERA		**********************
**********************																			**********************
************************************************************************************************************************

-----------------    Rangement des data dans les trames UDP	------------------------------------------------------------------

--   Entre 2 synchro, les data sont reparties dans des trames UDP avec au maximum 360 mots data de 32bit par trame.
--   La trame ne contient que des echantillons complets, c'est a dire avec tous les mots de 32 bit recut des boites bolo
--  la derniere trame peut-etre incomplete si Nb_synchro n'est pas divisible par 360
*/

typedef struct
	{
	uint4		identifiant;
	uint4		data[_nb_data_trame_udp];  //DEBUG: _nb_data_trame_udp = 360   -tb-
	}
Structure_trame_udp;


#define OPERA_TAILLE_DONNEES (_nb_data_trame_udp * sizeof(uint4))     //DEBUG: _nb_data_trame_udp = 360  also 360*4=1440 -tb-
#define OPERA_TAILLE_ENTETE (sizeof(Structure_trame_udp) - OPERA_TAILLE_DONNEES)  //DEBUG -tb-: Structure_trame_udp ohne Array = 1444-1440 = 4 = sizeof(uint4 identifiant)
#define nb_mots_entete_opera (OPERA_TAILLE_ENTETE/4)  //DEBUG -tb-: number of words of uint4		identifiant = 1

#define nb_mots_entete_fifo 4

//  contenue de l'entete des trames udp ordinaires

#define	_numero_trame(identifiant)			(identifiant&0xffff)					//  16 bits
#define	_temps_seconde_trame(identifiant)	((identifiant>>16) & 0x3fff)			//  14 bits


// je prend les temps que je shifte de 5 a droite: il reste a diviser par 25 * 125
// je commence par le poid fort et je prend le reste de la division par 125
// je le multiplie par 2^25 et le rajoute au poid faible shifte de 5 a droite
// je divise ce nombre par 125 (il reste a diviser par 25 )
// le poid fort divise par 125 doit etre shifte de 5 a droite puis de 30 a gauche soit 25 a gauche
// je perd 4 bit et le temps maxi sera 32 bit en seconde divise par 25 soit 2000 jours


//	 mots derives pouvant etre utilises directement
#define	_temps_seconde(pd_fort,pd_faible)	(((((pd_fort%125)<<25) + (pd_faible>>5)) /125 + ((pd_fort/125)<<25))/25)
#define	_temps_double(pd_fort,pd_faible)	( (int32_t double)(65536. * 16384.) * (int32_t double)pd_fort + (int32_t double)pd_faible ) / (int32_t double)100000.
#define _nb_mots_lecture_v1(masque_BB)		((masque_BB)&7)
#define _nb_mots_lecture_v2(masque_BB)		(((masque_BB)>>3)&7)
#define _nb_mots_lecture(masque_BB)		(((masque_BB)&7) + (((masque_BB)>>3)&7)?((masque_BB)&7) + (((masque_BB)>>3)&7):1)
#define _code_acqui_simple(code_acqui)		(code_acqui&0x1f)
#define _code_synchro_simple(code_synchro)		(code_synchro&0x3)
#define _code_synchro_esclave(trame)	((trame->enteteB>>8)&0x3)


//TODO: DEBUG -tb-  this are the menu options of the "mode combobox" of CEW_controle, so EDW_BB2 is 8, BB21 is 3;
//TODO: DEBUG -tb-  it is stored in Structure_status_opera as	uint4		code_acqui;
//TODO: DEBUG -tb-  which is the 4th word in Structure_status_opera or the 5th word in Structure_trame_status 
//TODO: DEBUG -tb-        ==> PROVED in udp284.txt and bb21-udp284.txt

//  les bit 0 a 4 du code d'acquisition  -->  32 codes possibles
#define 	code_acqui_test				0
#define 	code_acqui_EDW_BB1			1
#define 	code_acqui_EDW_BB1_moy4		2
#define 	code_acqui_EDW_BB21			3
#define 	code_acqui_synchro			4
#define 	code_acqui_ADC_moy2			5
#define 	code_acqui_ADC_moy2_comp	6
#define 	code_acqui_ADC_comp			7
#define 	code_acqui_EDW_BB2			8
#define		code_acqui_synchro_new		9
#define		code_acqui_veto				10
#define		code_acqui_test_emission	11
#define		code_acqui_test_reception	12
#define		code_acqui_BBv2_comp		13

//  le bit 5 du code d'acquisition permet le test de la boite OPERA en envoyant une donnee en dent de scie dans la fifo
#define 	code_acqui_option_test			0x20

#define	_nb_mesure_par_echantillon		{1	,1	,4	,1	,1	,2	,4	,8	,1	,1	,1	,1	,1	,1	,1	,1	,1	,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
#define	_nb_bit_horloge_par_echantillon	{60	,60	,240,60	,60	,36	,36	,72	,60	,1	,1	,1	,1	,60	,1	,1	,1	,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

#define _calcul_nb_mesure_par_echantillon(nb_mesure,code_acqui)\
	{\
	int table_nb_mesure[32]=_nb_mesure_par_echantillon;\
	nb_mesure = table_nb_mesure[_code_acqui_simple(code_acqui)];\
	}
	
#define _calcul_nb_bit_horloge_par_echantillon(nb_bit,code_acqui)\
	{\
	int table_nb_bit[32]=_nb_bit_horloge_par_echantillon;\
	nb_bit = table_nb_bit[_code_acqui_simple(code_acqui)];\
	}
		
//  le masque_BB  qui donne le nombre de canaux de 32bit a lire sur les boites bolos 1 et 2
#define		_masque(nb1,nb2)			(((int)(nb1)&0x7) | (((int)(nb2)&0x7)<<3))

//------   liste des codes synchro  
#define		code_synchro_20160			0
#define		code_synchro_25000			1
#define		code_synchro_100000			2
#define		code_synchro_esclave_synchro	4
#define		code_synchro_esclave_temps		8

//  les bit 0 et 1 du code synchro   -->  4 valeur possibles
#define		_valeur_synchro	{20160,25000,100000,100000}
//  le bit 2 et 3 du Code_synchro dit que l'horloge doit etre esclave (synchro et/ou temps)

#define _calcul_valeur_synchro(valeur,code_synchro)\
	{\
	int table_valeur_synchro[4]=_valeur_synchro;\
	valeur = table_valeur_synchro[(code_synchro)&0x03];\
	}
	

//  calcul du nombre d'echantillons et du nombre de mots dans la trame
//  ce define permet de definir les variables:
//  ne semble pas utilise actuellement
//	
#define	_def_constantes_trame(trame)																	\
			int Table_nb_synchro[8]			=	_valeur_synchro;										\
			int numero_trame				=	_numero_trame(trame);									\
			int nb_synchro					=	Table_nb_synchro[_code_synchro_simple(_code_synchro(trame)];			\
			int	nb_mots_lecture				=	(_nb_mots_lecture(trame)>0)?_nb_mots_lecture(trame):1;	\
			int	nb_echantillons_max_trame	=	_nb_data_trame_udp/nb_mots_lecture;						\
			int	nb_echantillons_trame		=	( (nb_synchro > numero_trame*nb_echantillons_max_trame)	\
					&&	(nb_synchro < (numero_trame+1) * nb_echantillons_max_trame) ) ?					\
					nb_synchro - numero_trame * nb_echantillons_max_trame:nb_echantillons_max_trame;	\
			uint32_t	temps_trame =temps_seconde(trame) ;         \
			int	nb_mots_trame =	nb_echantillons_trame * nb_mots_lecture;

//-----------------  3  --------  temps trame UDP    -----------------------------------------------------------------------

// le troisieme mot de la trame contient le temps en nombre de top synchro depuis le debut de la manip
// avec l'acquisition a 6MHz des BBv1, le top synchro est a la seconde et le temps est en secondes

//--------------------------------------------------------------------------------------------------------------------------

//************************************************************************************************************************
//**********************																			**********************
//**********************			Description des commandes UDP vers la carte OPERA				**********************
//**********************																			**********************
//************************************************************************************************************************


//Les commandes vers la carte OPERA sont constituees d'une trame UDP emise vers la carte OPERA (reconnue par son numero IP) sur le port :
#define _port_serveur_UDP		994
//  Le premier octet de la trame est un caractere de code suivit des donnees de la commande

// le deuxieme octet est un code de commande destine au FPGA (cyclone Altera)
#define		_FPGA_code_horloge		255
#define		_FPGA_code_EDW			240

//-----------------  1  -------------------     commande Port UDP   code    'P'		--------------------------------------
// cette commande permet de demander a la carte OPERA l'envoi des data vers l'ordinateur emetteur de la commande
// Cette commande a pour premier parametre un code indiquant le nombre de paquet de trames demande
//		Le programme envoie les trames, commencant a un top synchro et jusqu'au neme top synchro
//		ainsi	avec 0, l'emission s'arrete au prochain top synchro
//				avec 1: l'emission demarre au prochain top synchro et s'arrete au suivant
//		on peu demander au maximum 255 paquet. Il faut donc refaire une demande periodiquement avant la fin pour avoir une reception continue 
//	Le deuxieme parametre indique le port de reception ouvert sur l'ordinateur de commande qui sera utilise pour recevoir les data
		
//		-octet	0		'P'				code commande
//		-octet	1		nb_paquets		nombre de paquets demande
//		-octet	2		port			poid fort 
//		-octet	3		port			poid faible 

// une carte OPERA peu accepter un maximum de  _nb_max_clients_UDP  clients simultanes
#define	_nb_max_clients_UDP			20


//-----------------  2  -------------------     commande Horloge    code    'H'		--------------------------------------
//  C'est la commande permettant de fixer les parametres de la carte OPERA
/*		
		-octet	0		'H'					code commande
		-octet	1		_FPGA_code_horloge	code de commande vers le FPGA
		-octet	2		0					X	poid fort			La valeur du diviseur permettant de construire l'horloge de base a partir de 100MHz
		-octet	3		17					X	poid faible			Avec X=17, on a f=100/17 = 5.88 MHz  ->  98KHz d'echantillonage
		-octet	4		5					retard								Le retard pour gerer le delai du aux fibres: typiquement  retard=5
		-octet	5		2					masque_BB							typiquement 2 ou 16 pour une BBv1 , 18 pour 2 BBv1
																				8 pour code_acqui_synchro
		-octet	6		1					code_acqui							typiquement	1 pour code_acqui_EDW_BB1
																				4 pour code_acqui_synchro
		-octet	7		2					code_synchro						typiquement 14 pour 100000 points entre synchro en mode esclave
*/

//-----------------  3  -------------------     commande BoiteBolo Edelweiss    'W'		--------------------------------------
//  Cette commande est redirigee vers les boites bolos, sans etre prise en compte directement par la carte OPERA
// sont format est donc celui des boites bolos: adress, sous-adress, data
/*		
		-octet	0		'W'					code commande
		-octet	1		_FPGA_code_EDW		code de commande vers le FPGA
		-octet	2		0					adresse	(numero boite bolo)		
		-octet	3		17					sous-adresse
		-octet	4		5					data	poid fort	
		-octet	5		2					data	poid faible
*/


//-----------------  4  -------------------     commande mise a jour   code    'Q'		--------------------------------------
//  C'est la commande permettant d'arreter l'execution du programme, de faire une mise a jour et de redemarrer
/*		
		-octet	0		'Q'				code commande
		-octet	1		code			code de mise a jour
*/
/* extrait de CVS_EDW/Programmes/OPERA/OPERA_EDW/CEW_linux/cew.c:

case 0	:	mise_a_jour_et_redemarrage("/mnt/flash/startup","-0");		break;
case 1	:	mise_a_jour_et_redemarrage("/mnt/flash/startup","-1");		break;
case 2	:	mise_a_jour_bbv2(1);		break;   [ ndlr: (1) => commence par un startup -2, puis poursuit comme (0) ... ]
case 3	:	mise_a_jour_bbv2(0);		break;
case 4	:	mise_a_jour_et_redemarrage("/mnt/flash/startup","-a");		break;
case 5	:	sauve_config();		break;
case 8	:	max_print_time = 1;	printf("bavard\n");	break;
case 9	:	max_print_time = 100;	printf("discret\n");	break;
case 10 :	erreur_synchro_cew=0;erreur_timestamp=0;	break;

	sachant que:
		
	startup -0: arrete cew, le recharge, le dezippe, l'execute
	startup -1: arrete cew, recharge cew_c1, le dezippe, recharge l'Altera, execute cew
	startup -2: recharge bbv2.rbf et le dezippe
	startup -a: arrete cew et vire les gz, recharge tout, dezippe tout, recharge l'Altera, execute cew
	startup   : dezippe tout, recharge l'Altera, execute cew

			d'ou la liste de codes suivante:
*/

//	code==0	:	mise a jour de l'executable "cew" (en fait, lance un startup -0)
//					pour cela, elle fait un getftp de "cew" sur l'adrese IP mac_source (definie dans le fichier /etc/host) puis redemarre "cew"
//	code==1	:	mise a jour du Cyclone Altera dont le code est dans "c1.jbc" (en fait, lance un startup -1)
//					pour cela, elle fait un getftp de "c1.jbc" sur l'adrese IP PC_source (definie dans le fichier /etc/host)
//					ensuite, elle reconfigure le cyclone puis redemarre l'executable "cew"
//  code=3	:	chargement du programme BBv2.rbf de la boite OPERA vers la BBv2
//  code=2	:	demande la mise a jour du programme BBv2.rbf sur la carte OPERA a partir du mac
//					puis le chargement du programme BBv2.rbf de la boite OPERA vers la BBv2
//  code 4  :   recharge tout (startup -a)
//  code 5  :   sauve la config dans un fichier de /mnt/flash
//  code 6  :   (non attribue)
//  code 7  :   (non attribue)
//  code 8	:	l'affichage sur la console telnet passe en mode "bavard"
//  code 9	:	l'affichage sur la console telnet passe en mode "discret"
//  code 10	:	remise a zero des compteurs d'erreurs 

//-----------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//-------------------		description des commandes  vers  la  boite  BBv2		-------------------------------------
//-----------------------------------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------------

//pour BBv2:
//	Je garde les sous adresses  0x00  ..  0x10  comme avant:  
#define			ss_adrs_d2				0x02
#define			ss_adrs_d3				0x03
#define			ss_adrs_ident			0x08
#define			ss_adrs_alim			0x0a	
#define			ss_adrs_relais			0x1d
#define			ss_adrs_refDAC			0x1e
#define			ss_adrs_DAC1				0x11
#define			ss_adrs_DAC2				0x12
#define			ss_adrs_DAC3				0x13
#define			ss_adrs_DAC4				0x14
#define			ss_adrs_DAC5				0x15
#define			ss_adrs_DAC6				0x16
#define			ss_adrs_DAC7				0x17
#define			ss_adrs_DAC8				0x18
#define			ss_adrs_DAC9				0x19
#define			ss_adrs_DAC10				0x1a
#define			ss_adrs_DAC11				0x1b
#define			ss_adrs_DAC12				0x1c

// je mets apres 0x20 les commandes de compensations
#define			ss_adrs_triangle1			0x21
#define			ss_adrs_triangle2			0x22
#define			ss_adrs_triangle3			0x23
#define			ss_adrs_triangle4			0x24
#define			ss_adrs_triangle5			0x25
#define			ss_adrs_triangle6			0x26

#define			ss_adrs_carre1			0x27
#define			ss_adrs_carre2			0x28
#define			ss_adrs_carre3			0x29
#define			ss_adrs_carre4			0x2a
#define			ss_adrs_carre5			0x2b
#define			ss_adrs_carre6			0x2c

#define			ss_adrs_retard1			0x41
#define			ss_adrs_retard2			0x42
#define			ss_adrs_retard3			0x43
#define			ss_adrs_retard4			0x44
#define			ss_adrs_retard5			0x45
#define			ss_adrs_retard6			0x46

// je mets apres 0x30 les commandes de filtre et de gains
#define			ss_adrs_filtre1			0x31
#define			ss_adrs_filtre2			0x32
#define			ss_adrs_filtre3			0x33
#define			ss_adrs_filtre4			0x34
#define			ss_adrs_filtre5			0x35
#define			ss_adrs_filtre6			0x36


//  le mot a l'adresse ss_adrs_alim contient en bit0 le signal alim et en bit 1 le signal autorisation de commandes
// tous les codes actifs contiennent le bit 1 (autorisation) car tout code sans le bit1 bloque la boite
//  les codes d'ecriture sur l'adresse   ss_adrs_alim
#define			_bloque_commandes		0
#define			_autorise_commandes		6
#define			_eteint_alim			2
#define			_allume_alim			3
#define			_charge_dac_filtres		7

// la signification des bits du mot  code_alim:
//  bit0=alim   bit1=cmd_autorisees   bit2=charge_dac_filtre(ne reste pas)		bit4=data_comprimees

//  valeur du gain et de la frequence de coupure
//  gain entre 1 et 16 par pas de 1   et frequence  de 10 a 150 kHz par pas de 10
#define		_code_freq_gain(freq,gain)		((((((int)(freq))/10)&0xf)<<4)|(((int)(gain)-1)&0xf))
#define		_val_freq(code)		((((code)>>4)&0xf)*10)
#define		_val_gain(code)		(((code)&0xf)+1)


// controle de la regulation du point de fonctionnement avec les DAC
#define			ss_adrs_regul0			0x38
#define			ss_adrs_regul1			0x39
#define			ss_adrs_regul2			0x3a
#define			ss_adrs_regul3			0x3b
#define			ss_adrs_regul4			0x3c
#define			ss_adrs_regul5			0x3d
#define			ss_adrs_regul6			0x3e



//  le parametre ss_adrs_regul0	 contient le gain et le temps entre 2 corrections (en puissance de 2)
//#define		_code_regul(gain,temps)		(((((int)(gain))&0xff)<<8)|(((int)(temps))&0xff))
//#define		_regul_gain(code)			(((code)>>8)&0xff)
//#define		_regul_temps(code)			((code)&0xff)
//  les parametres suivants contiennent le numero du DAC a actionner (pour chaque ADC)
// le parametre ss_adrs_regul0  contient le temps de repetition de la regu (sur 4 bit
// les parametres suivants contiennent pour chaque ADC:
#define		_code_regul(gain,sa,sb,daca,dacb)		(((((int)(gain))&0xf))|((((int)(sa))&1)<<4)|((((int)(sb))&1)<<5)|((((int)(daca))&0xf)<<8)|((((int)(dacb))&0xf)<<12))
#define		_regul_gain(code)			((code)&0xf)
#define		_regul_sa(code)				(((code)>>4)&1)
#define		_regul_sb(code)				(((code)>>5)&1)
#define		_regul_daca(code)			(((code)>>8)&0xf)
#define		_regul_dacb(code)			(((code)>>12)&0xf)

//------------------------------------------------------------------------------------------------------------

// le numero du mot qui contient le bit de status (-1 signifie le dernier mot)
#define _position_bit_status	-1
//#define _position_bit_status	0
//  la position des differents mots dans le status renvoye par la boite BBv2
//  j'ai change l'ordre et rajoute les ADC moyenne

#define	status_nserie	0
#define	status_alim		1
#define	status_tempe	2
#define	status_div		3
#define	status_regul	5
#define	status_filtre	12
#define	status_adc		18
#define	status_dacBN	24
#define	status_triangle	38
#define	status_carre	44
#define	status_retard	50
#define	status_nb_erreurs	56

#define _nb_mots_status_bbv2 57	//  nombre de mots 16 bit du status BBv2  retournees dans le dernier bit de la voie 6

#define		_bbv2_nserie(pt)			(pt[status_nserie]&0xffff)
//#define		_bbv2_alim(pt)			(pt[status_alim]&0x01)
//#define		_bbv2_mode(pt)			((pt[status_alim]>>4)&0x0f)
//#define		_bbv2_blocage(pt)	((pt[status_alim]>>1)&0x01)
//#define		_bbv2_comprime(pt)	((pt[status_alim]>>4)&0x01)
#define		_bbv2_alim_bit(pt,bit)	((pt[status_alim]>>bit)&0x01)
#define		_bbv2_err_synchro(pt)	((pt[status_tempe]>>2)&0x01)
#define		_bbv2_temperature(pt)	(((double)((pt[status_tempe]>>4)&0xfff))/16.)
#define		_bbv2_div2(pt)			(pt[status_div]&0xffff)
//  le div2 dans status est a multiplier par 2 car c'est div2/2 que l'on a dans le fpga
#define		_bbv2_div3(pt)			(pt[status_div+1]&0xffff)
#define		_bbv2_relai1(pt)			((pt[status_dacBN+12]&0x01)!=0)
#define		_bbv2_relai2(pt)			((pt[status_dacBN+12]&0x02)!=0)
#define		_bbv2_relai3(pt)			((pt[status_dacBN+12]&0x04)!=0)
#define		_bbv2_ref(pt)			(pt[status_dacBN+13]&0x01)
#define		_bbv2_regul_t(pt)		(pt[status_regul]&0x0f)
#define		_bbv2_regul_gain(pt,nreg)	_regul_gain(pt[status_regul+nreg])
#define		_bbv2_regul_sa(pt,nreg)	_regul_sa(pt[status_regul+nreg])
#define		_bbv2_regul_sb(pt,nreg)	_regul_sb(pt[status_regul+nreg])
#define		_bbv2_regul_daca(pt,nreg)	_regul_daca(pt[status_regul+nreg])
#define		_bbv2_regul_dacb(pt,nreg)	_regul_dacb(pt[status_regul+nreg])
//#define		_bbv2_regul_gain(pt)		(_regul_gain(pt[status_regul]))
// Donne les parametres de regul  pour nadc = 1..6
//#define		_bbv2_regul_dac(pt,nadc)	(pt[status_regul+nadc]&0x0f)
// Donne le gain de l'adc pour nadc = 1..6
#define		_bbv2_gain(pt,nadc)	(_val_gain(pt[status_filtre+nadc-1]))
// Donne la frequence de coupure de l'adc pour nadc = 1..6
#define		_bbv2_freq(pt,nadc)	(_val_freq(pt[status_filtre+nadc-1]))
// Donne la valeur moyenne de l'adc pour nadc = 1..6
#define		_bbv2_adc(pt,nadc)	((pt[status_adc+nadc-1]&0xffff)-0x8000)
// Donne la valeur du DAC pour ndac = 1..12
#define		_bbv2_dac(pt,ndac)	((pt[status_dacBN+ndac-1]&0xffff)-0x8000)
// Donne la valeur du triangle pour ndac = 1..6
#define		_bbv2_tri(pt,ndac)	((pt[status_triangle+ndac-1]&0xffff)-0x8000)
// Donne la valeur du carre pour ndac = 1..6
#define		_bbv2_car(pt,ndac)	((pt[status_carre+ndac-1]&0xffff)-0x8000)
#define		_bbv2_nb_erreurs(pt)	(pt[status_nb_erreurs]&0xffff)


//----- le status sera range dans une trame speciale decrite par la structure suivante
typedef struct
	{
	uint4		temps_pd_fort;
	uint4		temps_pd_faible;
	uint4		temps_seconde;
	uint4		code_acqui;
	uint4		masque_BB;
	uint4		code_synchro;
	uint4		registre_x;
	uint4		registre_retard;
	uint4		micro_bbv2;
	//short		nb_erreurs_corrige;
	uint4		nb_erreurs_synchro_cew;
	uint4		nb_erreurs_timestamp;
	uint4		erreurs_synchro_opera;
	uint4		version_cew;
	}
Structure_status_opera;

#define _nb_mots_structure_status_opera	((int)sizeof(Structure_status_opera)/4)


typedef struct
	{
	uint4							identifiant;			// ne contient que 0xffff en poid faible pour indiquer une trame de status
	Structure_status_opera			status_opera;
	int4		status_bbv2_1[_nb_mots_status_bbv2];	//_nb_mots_status_bbv2 = 57 -tb-
	}
Structure_trame_status;

//-----------------------------------------------------------------------------------------------------------tb-
//----- Defines for the BBv2/BBv3 status bits and commands
//-----    1.) command adressing
//-----    2.) BB status bits
//-----------------------------------------------------------------------------------------------------------tb-
//
//
// 1.)
// general form: (W command) 
// 0xf0 0xNN CMD ARG1 ARG2
// 0xf0 means 'W' command
// 0xNN BB identifier, 0xff broadcast
// CMD is the sub adress, in the example below: CMD=0x31 writes filter arguments for ADC1 (..., ..., freq., gain)
//                                              CMD=0x31 writes filter arguments for ADC2 (..., ..., freq., gain)
//                                              etc.
// ARG1 ARG2: command args
// e.g. 
// 0xf0 0xff 0x31 0x12 0x34 will write 0x1234 to the filter parameters of ADC1; see example 2.)
// 
// 
// see from line 360 on, '//pour BBv2:':
// e.g.
// // je mets apres 0x30 les commandes de filtre et de gains
// #define			ss_adrs_filtre1			0x31
// ...
// 


#define			ss_adrs_d2				0x02
#define			ss_adrs_d3				0x03
#define			ss_adrs_ident			0x08
#define			ss_adrs_alim			0x0a	
#define			ss_adrs_relais			0x1d
#define			ss_adrs_refDAC			0x1e
#define			ss_adrs_DAC1				0x11

#define kBBcmdSetD2        0x02  //kBBstatusD2=3
#define kBBcmdSetD3        0x03  //kBBstatusD3=4

#define kBBcmdSetIdentMode 0x08
#define kBBcmdAlim         0x0a  //kBBstatusAlim=1
#define kBBcmdSetRelais    0x1d  //kBBstatusRelais=36
#define kBBcmdSetRefDAC    0x1e  //kBBstatusRefDAC=37   = ref  (in cew_control, near relais settings)

//ARRAYS:

//polar dac (12 settings, 0x11 bis 0x1c) - BBstatus: kBBstatusDAC      24
#define kBBcmdSetDAC       0x11

//triangle - BBstatus: index 38=kBBstatusTri
#define kBBcmdSetTri       0x21
//rectangle - BBstatus: index 44=kBBstatusRect
#define kBBcmdSetRect      0x27

//filter is: frequency (f) and gain (g) (0x00fg) for ADC1..6 (in BBstatus at index 12..17, status_filtre/kBBstatusFilter)
#define kBBcmdSetFilter    0x31


//Rg + Rt (controle de la regulation du point de fonctionnement avec les DAC)  (g=gain (?), t=time=time steps (?))
#define kBBcmdSetRt        0x38
//Rt is reg. tous? (in BBstatus at index 5=status_regul/kBBstatusRt)

#define kBBcmdSetRg        0x39
//base for Rg for ADC1...6  (in BBstatus at index 6=status_regul+1/kBBstatusRg)
//format: 0xBB 0xCmd 0xBT 0xSR with: B=bottom dac value (dacb), T=top dac value (daca),  S=signs (bit0/bit1 = top/bottom resp. sa/sb sign), R=Rg value


//retard (BBstatus: index 50=kBBstatusRetard)
#define kBBcmdSetRetard    0x41


// 2.)
// The BB status packet is a array of 57 shorts, this are the (start) indices for the according setting blocks
// e.g. status_filtre is 12 (and next index 18 -> block of 6 values):
//    each word contains: freq in bits 4...7, gains (multiplier) in bits0...3
// After writing the command 0xf0 0xff 0x31 0x12 0x34 we will find the value 0x1234 in the short 'BBstatusArray[status_filtre=12]'
// etc.
// #define	status_nserie	0
// #define	status_alim		1
// #define	status_tempe	2
// #define	status_div		3
// #define	status_regul	5
// #define	status_filtre	12
// #define	status_adc		18
// #define	status_dacBN	24
// #define	status_triangle	38
// #define	status_carre	44
// #define	status_retard	50
// #define	status_nb_erreurs	56
// #define _nb_mots_status_bbv2 57	//  nombre de mots 16 bit du status BBv2  retournees dans le dernier bit de la voie 6

#define kBBstatusSerNum    0
#define kBBstatusAlim      1
#define kBBstatusTemperature 2
#define kBBstatusD2        3
#define kBBstatusD3        4
#define kBBstatusRt        5
#define kBBstatusRg        6
#define kBBstatusFilter   12
#define kBBstatusADCValue 18
#define kBBstatusDAC      24
#define kBBstatusRelais   36  //this contains now: ref, ADC 1..4 on/off, relais 1, relais 2, mez. 1, mez. 2
#define kBBstatusRefDAC   37  //????
#define kBBstatusTri      38
#define kBBstatusRect     44
#define kBBstatusRetard   50

//bit fields
//for #define kBBstatusRelais   36  //this contains now: ref, ADC 1..4 on/off, relais 1, relais 2, mez. 1, mez. 
#define kBBRefMask        0x1
#define kBBRefShift       0
#define kBBADCMask        0x1e
#define kBBADCShift       1    //ADC 1..4
#define kBBRelais1Mask    0x60  //ADC 1..4
#define kBBRelais1Shift   5
#define kBBRelais2Mask    0x180
#define kBBRelais2Shift   7
#define kBBMezMask        0x600
#define kBBMezShift       9
//#define kBBMez1Mask       0x200
//#define kBBMez1Shift      9
//#define kBBMez2Mask       0x400
//#define kBBMez2Shift      10


//-----------------------------------------------------------------------------------------------------------tb-
//----- Definition of the KIT/IPE crate status packets
//-----    1.) Header
//-----    2.) Crate Status
//-----    3.) BB Status
//-----------------------------------------------------------------------------------------------------------tb-

// (u)int32_t MUST be same size as (u)int4  (32 bit/4 byte) 



//-----    1.) Header
//the header is a 32 bit (unsigned) integer and can be regarded as two 16 bit (short unsigned) integers
typedef struct {
	uint32_t identifiant;	 // 0x0000ffff = synchro packet -> first block is a TypeIpeCrateStatusBlock (+ maybe other status packets)
	                         // 0x0000fffe = status packet  -> contains one or more BB status blocks TypeBBStatusBlock
} TypeStatusHeader;



//-----    2.) Crate Status
// crate status C (60 bytes)
typedef struct {
	uint32_t stamp_msb;        // previously in cew: temps_pd_fort
	uint32_t stamp_lsb;        // previously in cew: temps_pd_faible
	uint32_t PPS_count;        // computed from the header pattern in the data stream (previously in cew: temps_seconde (time in  seconds))
	uint32_t size_bytes;       // = sizeof(TypeIpeCrateStatusBlock)
    //SLT register:
	uint32_t SLTTimeLow;       // the according SLT register
	uint32_t SLTTimeHigh;      // the according SLT register
	uint32_t OperaStatus1;     // contains d0, previously in cew: registre_x, =20  
	uint32_t pixbus_enable;
    //software (ipe4reader) status:
	uint32_t prog_status;      // previously in cew: micro_bbv2, BBv2/2.3/3 programming
	uint32_t error_counter;
	uint32_t internal_error_info;
	uint32_t ipe4reader_status;
	uint32_t version;          // _may_ be useful in some particular cases (version of C code/firmware/hardware?) 
	uint32_t numFIFOnumADCs;   // numfifo (& 0xffff0000)  and total number of ADCs in the UDP data packets (&0xffff)
	uint32_t maxUDPSize;       // variable UDP packet size: this is the size dedicated to this FIFO
	uint32_t spare1;           // reserved for future usage
	uint32_t spare2;           // reserved for future usage
	uint32_t spare3;           // reserved for future usage
	uint32_t spare4;           // reserved for future usage
	uint32_t spare5;           // reserved for future usage
} TypeIpeCrateStatusBlock;


//-----    3.) BB Status Block

// BB status block B (128 bytes)
typedef struct {
	uint32_t size_bytes;                        // = sizeof(TypeBBStatusBlock)
	unsigned char type;                         //(starts counting at 0)
	unsigned char crateIndex;                   //(starts counting at 0)
	unsigned char fltIndex;                     //(starts counting at 0)
	unsigned char fiberIndex;                   //(starts counting at 0)
	uint32_t spare;                             // reserved for future usage
	uint16_t bb_status[_nb_mots_status_bbv2];	//_nb_mots_status_bbv2 = 57 -tb-
	uint16_t spare_for_alignment;              // added for alignment
} TypeBBStatusBlock;





/*--------------------------------------------------------------------
 *    UDP packed definitions
 *       data, IPE crate status  -tb-
 *--------------------------------------------------------------------*/ //-tb-

//size: id + header + 21*16 + UDPFIFOmap + IPmap = (1 + 8 + 336 + 5 + 20) 32-bit words = 1480 bytes
#define MAX_NUM_FLT_CARDS 20
#define MAX_NUM_FLT_PAGES 16
#define MAX_FLT_PAGE_LENGTH 4096

#define IPE_BLOCK_SIZE    16
  //TODO: is also defined in EdelweissSLTv4_HW_Definitions.h, remove one of them -tb-

#define MAX_UDP_STATUSPACKET_SIZE 1480
#define SIZEOF_UDPStructIPECrateStatus 1480

typedef struct{
    //identification
    union {
	    uint32_t		id4;  //packet header: 16 bit id=0xFFD0 + 16 bit reserved
	    struct {
	        uint16_t id0; 
	        uint16_t id1;};
	};
	
    //header
	uint32_t		presentFLTMap;
	uint32_t		reserved0;
	uint32_t		reserved1;
	
	//SLT info (16 words)
	uint32_t    SLT[IPE_BLOCK_SIZE];                   //one 16 word32 block for the SLT

    //FLT info (20x16 = 320 words)
	uint32_t    FLT[MAX_NUM_FLT_CARDS][IPE_BLOCK_SIZE];//twenty FLTs, one 16 word32 block per each FLT
    
    //IP Adress Map (20 words)
	uint32_t		IPAdressMap[MAX_NUM_FLT_CARDS];    //IP address map associated to the according SLT/HW FIFO
    //Port Map      (10 words)
	uint16_t		PortMap[MAX_NUM_FLT_CARDS];        //IP address map associated to the according SLT/HW FIFO
}
UDPStructIPECrateStatus;


//moved to ipe4reader.cpp globals -tb-UDPStructIPECrateStatus IPECrateStatusPacket;


//struct def of UDPStructIPECrateStatus in human readable format
//----------------------------------------------------------------
typedef struct{
    uint32_t  SLTControlReg;
    uint32_t  SLTStatusReg;
    uint32_t  SLTVersionReg;
    uint32_t  SLTPixbusEnableReg;
    uint32_t  SLTTimeLowReg;
    uint32_t  SLTTimeHighReg;
    uint32_t  word6;
    uint32_t  word7;
    uint32_t  word8;
    uint32_t  word9;
    uint32_t  word10;
    uint32_t  word11;
    uint32_t  word12;
    uint32_t  word13;
    uint32_t  word14;
    uint32_t  word15;
}
SLTBlock;

typedef struct{
    uint32_t  FLTStatusReg;
    uint32_t  FLTControlReg;
    uint32_t  FLTVersionReg;
    uint32_t  FLTFiberSet_1Reg;
    uint32_t  FLTFiberSet_2Reg;
    uint32_t  FLTStreamMask_1Reg;
    uint32_t  FLTStreamMask_2Reg;
    uint32_t  FLTTriggerMask_1Reg;
    uint32_t  FLTTriggerMask_2Reg;
    uint32_t  word9;
    uint32_t  word10;
    uint32_t  word11;
    uint32_t  word12;
    uint32_t  word13;
    uint32_t  word14;
    uint32_t  word15;
}
FLTBlock;



typedef struct{
	uint16_t id0;   //=0xFFD0
	uint16_t id1;
	
    //header
	uint32_t		presentFLTMap;
	uint32_t		reserved0;
	uint32_t		reserved1;
	
	
	//SLT info
	SLTBlock    SLT;            //one 16 word32 block for the SLT

    //FLT info
	FLTBlock    FLT[MAX_NUM_FLT_CARDS];//twenty FLTs, one 16 word32 block per each FLT
    
    
    //IP Adress Map (20 words)
	uint32_t		IPAdressMap[MAX_NUM_FLT_CARDS];    //IP address map associated to the according SLT/HW FIFO
    //Port Map      (10 words)
	uint16_t		PortMap[MAX_NUM_FLT_CARDS];        //IP address map associated to the according SLT/HW FIFO
    
}
UDPStructIPECrateStatus2;





/*----------------------------------   le compresseur pour ADC simple  -----------------------------------------
//  Le compresseur range 8 donnees successives dans un mot de 64 bit range poid fort d'abord
//  On a dans l'ordre, en commencant par le poid fort:
//  -  a1 sur 15 bit
//  -  a2 a3 , ...  a8   sur 7 bit chacun  ce qui fait bien  7*7 + 15 = 64
//  a1 contient la premiere valeure sur 14 bit, precedee d'un zero puis eventuellement shifte a droite de k points en rajoutant des 1 par la gauche 
// en shiftant a1 vers la gauche jusqu a retrouver le zero en poid fort, on retrouve la premiere valeure ainsi que la valeur de k
// les data a2 .. a8 contiennent les differences signee entre une valeur et la precedente, shifte de k vers la droite.
// k est ajuste par le programme de compression pour qu'aucune des differences ne depasse +- 63 (nombre signe sur 7 bit)
// Pour retrouver les valeurs suivantes, il suffit, avant le shift a gauche, d'ajouter a a1, successivement a2, a3,... en valeur signe sur 7 bit
// puis de shifter a gauche toutes les valeures de k
//  si tabin est un pointeur sur les data rangees dans un tableau de mots de 32 bit, on a :
a1=(*tabin  >>17) & 0x7fff;		// 15 bit
a2=(*tabin  >>10) & 0x7f;	a2=a1 + a2 - 0x40 ;		//  soustrait la demidif
a3=(*tabin  >> 3) & 0x7f;	a3=a2 + a3 - 0x40 ;	
a4=( (*tabin & 0x7) << 4 );
tabin++;
a4+= ((*tabin >> 28)&0x0f);	a4=a3 + a4 - 0x40 ;	
a5=(*tabin >> 21) & 0x7f;	a5 =a4 + a5 - 0x40 ;	
a6=(*tabin >> 14) & 0x7f;	a6 =a5 + a6 - 0x40 ;	
a7=(*tabin >>  7) & 0x7f;	a7 =a6 + a7 - 0x40 ;	
a8=(*tabin >>  0) & 0x7f;	a8 =a7 + a8 - 0x40 ;	
tabin++;
// j'ai retrouve ici les valeurs brutes de a1 , a2, ..  a8 . Il reste a faire le shift a gauche
k=0;
while(a1&0x4000) {k++;
	a1=(a1<<1) & 0x7fff;
	a2=(a2<<1) & 0x7fff;
	a3=(a3<<1) & 0x7fff;
	a4=(a4<<1) & 0x7fff;
	a5=(a5<<1) & 0x7fff;
	a6=(a6<<1) & 0x7fff;
	a7=(a7<<1) & 0x7fff;
	a8=(a8<<1) & 0x7fff;
	}
//  pour retrouver les valeurs signe (le compresseur ne marche qu'avec des entiers non signes sur 14 bit) faire a = (a - 0x2000) 
*/







