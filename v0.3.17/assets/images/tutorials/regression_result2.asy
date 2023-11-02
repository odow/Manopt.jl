import settings;
import three;
import solids;unitsize(4cm);

currentprojection=perspective( camera = (1.0, 0.5, 0.5), target = (0.0, 0.0, 0.0) );
currentlight=nolight;

revolution S=sphere(O,0.995);
pen SpherePen = rgb(0.85,0.85,0.85)+opacity(0.6);
pen SphereLinePen = rgb(0.75,0.75,0.75)+opacity(0.6)+linewidth(0.5pt);
draw(surface(S), surfacepen=SpherePen, meshpen=SphereLinePen);

/*
  Colors
*/
pen curveStyle1 = rgb(0.0,0.0,0.0)+linewidth(0.33pt)+opacity(1.0);
pen curveStyle2 = rgb(0.0,0.6,0.5333333333333333)+linewidth(0.66pt)+opacity(1.0);
pen curveStyle3 = rgb(0.0,0.4666666666666667,0.7333333333333333)+linewidth(0.33pt)+opacity(1.0);
pen pointStyle1 = rgb(0.0,0.4666666666666667,0.7333333333333333)+linewidth(3.5pt)+opacity(1.0);
pen pointStyle2 = rgb(0.9333333333333333,0.4666666666666667,0.2)+linewidth(3.5pt)+opacity(1.0);
pen pointStyle3 = rgb(0.0,0.6,0.5333333333333333)+linewidth(2.5pt)+opacity(1.0);
pen tVectorStyle1 = rgb(0.9333333333333333,0.4666666666666667,0.2)+linewidth(1.0pt)+opacity(1.0);

/*
  Exported Points
*/
dot( (0.9628597552275074,-0.2586336178270214,0.07752253538765819), pointStyle1);
dot( (0.9270001808186163,-0.3258582905215327,0.1857068637951671), pointStyle1);
dot( (0.9450146911101766,-0.174193815534695,0.2767738214054969), pointStyle1);
dot( (0.6391065469387733,0.0630132147194146,0.7665325540580271), pointStyle1);
dot( (0.3954152746221792,-0.025681615333134372,0.9181433522219432), pointStyle1);
dot( (0.4240088476496956,0.3491964693199686,0.8356304942552333), pointStyle1);
dot( (0.3307273018451248,0.5568151209421528,0.7619556239732203), pointStyle1);
dot( (0.7639620330594684,0.024619949473770695,0.6447913384433398), pointStyle2);
dot( (0.9388962067821709,-0.28241373571708434,0.1967648209624176), pointStyle3);
dot( (0.8664189335165672,-0.0990359260245375,0.4893977084135943), pointStyle3);
dot( (0.9332518519658246,-0.35518460369045146,0.05371106127806191), pointStyle3);
dot( (0.7019277421741605,0.08296676676679689,0.7073994348163913), pointStyle3);
dot( (0.4389750703887655,0.2695695342786837,0.8571074342029432), pointStyle3);
dot( (0.23085766743406855,0.37617543192181313,0.8973275777581667), pointStyle3);
dot( (0.5392231098833815,0.20698404759935235,0.8163308409015823), pointStyle3);

/*
  Exported Curves
*/
path3 p1 = (0.4754988238681391,0.4867943363073806,0.7327565370838212) .. (0.48428300654300027,0.48302665028331326,0.7294897015652477) .. (0.493017778046662,0.4792096812734947,0.7261484365497787) .. (0.5017022471744275,0.47534381872150794,0.7227330829451382) .. (0.5103355278539276,0.47142945705952133,0.7192439892182749) .. (0.5189167392355271,0.46746699566804506,0.7156815113598087) .. (0.5274450057821971,0.4634568388351824,0.7120460128477077) .. (0.5359194573588458,0.4593993957153806,0.7083378646102038) .. (0.544339229321098,0.4552950802876846,0.7045574449879469) .. (0.5527034626035141,0.45114431131349975,0.7007051396954029) .. (0.5610113038072402,0.44694751229386465,0.696781341781499) .. (0.5692619052870804,0.4427051114262426,0.6927864515895221) .. (0.5774544252379812,0.4384175415608321,0.6887208767162709) .. (0.5855880277809207,0.4340852401564039,0.6845850319704695) .. (0.5936618830481929,0.42970864923566654,0.6803793393304449) .. (0.6016751672680785,0.42528821534016803,0.676104227901072) .. (0.6096270628488945,0.42082438948473416,0.6717601338699929) .. (0.6175167584624119,0.41631762711145287,0.6673475004631129) .. (0.6253434491266362,0.4117683880432048,0.6628667778993776) .. (0.6331063362879381,0.4071771364367484,0.6583184233448383) .. (0.6408046279025309,0.40254434073536177,0.6537029008660066) .. (0.6484375385172808,0.39787047362104777,0.6490206813825065) .. (0.656004289349848,0.3931560119663069,0.6442722426190268) .. (0.6635041083681441,0.38840143678548134,0.6394580690565785) .. (0.6709362303691031,0.383607233185678,0.6345786518830638) .. (0.6782998970567542,0.37877389031727327,0.6296344889431605) .. (0.6855943571195907,0.3739019013240046,0.6246260846875269) .. (0.6928188663072257,0.36899176329265604,0.619553950121333) .. (0.6999726875063276,0.3640439772023402,0.614418602752123) .. (0.707055090815828,0.3590590478733838,0.6092205665370141) .. (0.7140653536213923,0.35403748391582085,0.6039603718292376) .. (0.7210027606691486,0.3489797976774998,0.5986385553240267) .. (0.7278666041386639,0.3438865051918086,0.5932556600038584) .. (0.7346561837151634,0.3387581261250241,0.5878122350830531) .. (0.7413708066609823,0.3335951837232909,0.582308835951738) .. (0.7480097878862473,0.3283982047592346,0.5767460241191813) .. (0.7545724500187736,0.3231677194782155,0.5711243671565018) .. (0.7610581234731792,0.3179042615442281,0.5654444386387597) .. (0.7674661465192005,0.31260836798545116,0.5597068180864351) .. (0.77379586534921,0.30728057913945545,0.5539120909062992) .. (0.780046634144922,0.3019214385980731,0.5480608483316868) .. (0.7862178151432877,0.2965314931519351,0.5421536873621714) .. (0.792308778701563,0.2911112927346828,0.5361912107026554) .. (0.7983189033615534,0.28566139036685817,0.5301740267018747) .. (0.804247575913019,0.28018234209947945,0.5241027492903304) .. (0.8100941914562412,0.27467470695730756,0.5179779979176491) .. (0.8158581534637398,0.26913904688180906,0.5118003974893809) .. (0.8215388738411368,0.26357592667382146,0.5055705783032406) .. (0.8271357729871592,0.2579859139359269,0.49928917598479877) .. (0.8326482798527752,0.2523695790145398,0.49295683142262914) .. (0.838075831999459,0.2467274949417151,0.48657419070291896) .. (0.8434178756565748,0.24106023737668142,0.4801419050435493) .. (0.8486738657778786,0.2353683845471073,0.47366063072765124) .. (0.8538432660971292,0.22965251719010465,0.4671310290366459) .. (0.8589255491828025,0.22391321849297674,0.4605537661827742) .. (0.8639201964919057,0.2181510740337154,0.4539295132411236) .. (0.8688266984228836,0.21236667172125506,0.4472589460811581) .. (0.8736445543676132,0.20656060173548868,0.44054274529776044) .. (0.8783732727624805,0.20073345646705187,0.43378159614179046) .. (0.8830123711385344,0.19488583045688157,0.4269761884501698) .. (0.887561376170713,0.18901832033555532,0.4201272165754982) .. (0.8920198237261365,0.1831315247624174,0.41323537931520854) .. (0.896387258911463,0.17722604436449774,0.4063013798402694) .. (0.9006632361192999,0.17130248167523038,0.3993259256234407) .. (0.9048473190736701,0.16536144107297707,0.3923097283670902) .. (0.908939080874525,0.15940352871936297,0.3852535039305793) .. (0.9129381040413002,0.15342935249743042,0.3781579722572241) .. (0.9168439805555111,0.1474395219496164,0.37102385730083987) .. (0.9206563119023837,0.14143464821556184,0.36385188695187654) .. (0.9243747091115133,0.13541534396975669,0.356642792963152) .. (0.9279987927965525,0.1293822233590296,0.349397310875192) .. (0.9315281931939187,0.1233359019398864,0.3421161799411834) .. (0.9349625502005217,0.11727699661570543,0.33480014305154815) .. (0.938301513410504,0.11120612557379483,0.32744994665814675) .. (0.9415447421509939,0.10512390822231957,0.3200663406981181) .. (0.9446919055168626,0.09903096512710338,0.31265007851736387) .. (0.9477426824044872,0.09292791794831237,0.30520191679368447) .. (0.9506967615445129,0.08681538937702793,0.2977226154595763) .. (0.953553841533611,0.08069400307171345,0.2902129376246956) .. (0.9563136308652317,0.07456438359458278,0.282673649497999) .. (0.9589758479593453,0.06842715634787644,0.2751055203095674) .. (0.9615402211911735,0.062282947510052394,0.2675093222321222) .. (0.9640064889189008,0.05613238397189674,0.25988583030224016) .. (0.9663743995103717,0.04997609327256308,0.2522358223412774) .. (0.9686437113687638,0.04381470353554448,0.24456007887600853) .. (0.9708141929572373,0.03764884340458638,0.23685938305898951) .. (0.9728856228225595,0.03147914197954649,0.22913452058865333) .. (0.9748577896176995,0.025306228752208115,0.22138627962914562) .. (0.9767304921233908,0.019130733542053052,0.2136154507299081) .. (0.9785035392686632,0.012953286432001776,0.20582282674501978) .. (0.980176750150336,0.006774517704126182,0.1980092027523021) .. (0.9817499540514771,0.000595057775342106,0.1901753759721977) .. (0.9832229904588198,-0.00558446286691161,0.18232214568643001) .. (0.9845957090791406,-0.011763413729001582,0.17445031315645337) .. (0.9858679698545937,-0.01794116437542881,0.16656068154170062) .. (0.9870396429770004,-0.024117084493151753,0.15865405581763659) .. (0.988110608901094,-0.030290543955896865,0.15073124269362764) .. (0.9890807583567163,-0.03646091288845013,0.14279305053063285) .. (0.9899499923599672,-0.04262756173092286,0.13484028925872754) .. (0.9907182222233033,-0.048789861302985404,0.1268737702944664);
 draw(p1, curveStyle1);
path3 p2 = (0.3973418115340176,0.29321225224909964,0.8695665931588428) .. (0.4061398261935752,0.2883211610955387,0.86713398598139) .. (0.4148942842200203,0.2833991488201807,0.8646083826620898) .. (0.4236042467378924,0.2784467432862615,0.8619900540603114) .. (0.43226877964367033,0.2734644756165543,0.8592792809797847) .. (0.4408869537059501,0.2684528801364097,0.8564763541384868) .. (0.44945784466510097,0.2634124943164512,0.8535815741374624) .. (0.4579805333323884,0.25834385871493426,0.8505952514285864) .. (0.46645410568855233,0.25324751691977376,0.8475177062812687) .. (0.47487765298183165,0.24812401549024665,0.8443492687481073) .. (0.4832502718254239,0.24297390389837628,0.8410902786294925) .. (0.49157106429436936,0.23779773447000374,0.8377410854371626) .. (0.4998391380218487,0.2325960623255534,0.8343020483567227) .. (0.5080536062948862,0.22736944532049919,0.8307735362091224) .. (0.5162135881494451,0.22211844398553668,0.8271559274111018) .. (0.524318208464907,0.21684362146646904,0.8234496099346079) .. (0.5323665980579245,0.21154554346381219,0.8196549812651865) .. (0.5403578937756375,0.20622477817212595,0.8157724483593541) .. (0.548291238588242,0.20088189621907768,0.8118024276009528) .. (0.5561657816809025,0.1955174706042454,0.8077453447564954) .. (0.5639806785449981,0.1901320766376659,0.8036016349295048) .. (0.5717350910686931,0.18472629187813558,0.7993717425138493) .. (0.5794281876268188,0.17930069607126975,0.7950561211460856) .. (0.5870591431700629,0.17385587108732775,0.7906552336568061) .. (0.5946271393134523,0.16839240085880985,0.7861695520210047) .. (0.60213136442412,0.1629108713178333,0.7815995573074571) .. (0.6095710137083499,0.1574118703332938,0.7769457396271312) .. (0.6169452892978873,0.15189598764781914,0.7722085980806226) .. (0.6242534003355061,0.1463638148145222,0.7673886407046298) .. (0.6314945630598252,0.14081594513355938,0.7624863844174685) .. (0.6386680008893624,0.135252973588502,0.7575023549636358) .. (0.64577294450582,0.12967549678252707,0.7524370868574254) .. (0.6528086319365907,0.12408411287443419,0.7472911233256034) .. (0.659774308636475,0.11847942151449599,0.742065016249151) .. (0.6666692275686033,0.11286202378014817,0.7367593261040759) .. (0.6734926492845519,0.10723252211152676,0.7313746219013053) .. (0.6802438420036456,0.10159152024685934,0.7259114811256617) .. (0.6869220816914378,0.09593962315771667,0.7203704896739301) .. (0.6935266521373595,0.09027743698413233,0.7147522417920232) .. (0.7000568450315303,0.08460556896959708,0.7090573400112515) .. (0.7065119600407209,0.07892462739593462,0.7032863950837045) .. (0.7128913048834606,0.0732352215180663,0.6974400259167504) .. (0.7191941954042816,0.06753796149867125,0.6915188595066608) .. (0.7254199556470912,0.06183345834274924,0.685523530871369) .. (0.7315679179276653,0.05612232383209319,0.6794546829823658) .. (0.7376374229052544,0.05040517045967843,0.6733129666957459) .. (0.7436278196532944,0.04468261136397556,0.6670990406824043) .. (0.7495384657292167,0.038955260263194236,0.6608135713573986) .. (0.7553687272433454,0.033223731389464654,0.6544572328084777) .. (0.7611179789268809,0.02748863942296399,0.6480307067237902) .. (0.766785604198956,0.021750599425994794,0.6415346823187759) .. (0.7723709952327615,0.016010226777022338,0.6349698562622501) .. (0.7778735530207331,0.010268137104678134,0.6283369326016903) .. (0.7832926874387922,0.004524946221736562,0.6216366226877289) .. (0.7886278173096338,-0.0012187299409282017,0.6148696450978653) .. (0.7938783704650549,-0.006962275400397969,0.6080367255594012) .. (0.7990437838073182,-0.012705074187771854,0.6011385968716099) .. (0.8041235033695396,-0.018446510414226153,0.5941759988271462) .. (0.8091169843751003,-0.02418596833706554,0.5871496781327084) .. (0.8140236912960711,-0.02992283242575869,0.5800603883289563) .. (0.8188430979106454,-0.035656487427951106,0.5729088897096978) .. (0.8235746873595735,-0.04138631843544806,0.5656959492403507) .. (0.8282179522015941,-0.04711171095016075,0.55842234047569) .. (0.8327723944678549,-0.05283205095000833,0.5510888434768861) .. (0.8372375257153175,-0.05854672495476901,0.5436962447278486) .. (0.8416128670791398,-0.06425512009187301,0.5362453370508782) .. (0.8458979493240336,-0.06995662416213021,0.5287369195216406) .. (0.8500923128945868,-0.07565062570538589,0.5211717973834697) .. (0.8541955079645487,-0.0813365140660969,0.5135507819610082) .. (0.8582070944850724,-0.08701367945882166,0.5058746905731973) .. (0.8621266422319076,-0.09268151303361695,0.4981443464456228) .. (0.86595373085154,-0.09833940694133421,0.49036057862222765) .. (0.8696879499062729,-0.10398675439880845,0.48252422187640165) .. (0.873328898918244,-0.10962294975393327,0.47463611662145466) .. (0.8768761874123752,-0.11524738855061398,0.4666971088204873) .. (0.8803294349582496,-0.12085946759359285,0.45870804989566427) .. (0.8836882712109102,-0.126458585013139,0.4506697966369039) .. (0.8869523359505784,-0.13204414032959633,0.4425832111099912) .. (0.8901212791212854,-0.13761553451778194,0.43444916056412497) .. (0.8931947608684141,-0.143172170071229,0.4262685173389098) .. (0.8961724515751475,-0.1487134510662666,0.4180421587708013) .. (0.8990540318978181,-0.1542387832259298,0.4097709670990157) .. (0.9018391928001559,-0.1597475739836929,0.4014558293709142) .. (0.9045276355864317,-0.16523923254701986,0.39309763734687087) .. (0.9071190719334905,-0.17071316996072392,0.38469728740463516) .. (0.9096132239216729,-0.1761687991701301,0.3762556804432004) .. (0.9120098240646204,-0.18160553508403454,0.3677737217861854) .. (0.9143086153379625,-0.18702279463745258,0.35925232108474375) .. (0.9165093512068814,-0.19241999685414984,0.3506923922200068) .. (0.9186117956525515,-0.19779656290894934,0.34209485320507493) .. (0.9206157231974512,-0.2031519161898077,0.3334606260865649) .. (0.9225209189295451,-0.2084854823596544,0.3247906368457237) .. (0.924327178525331,-0.21379668941798638,0.316085815299122) .. (0.9260343082717539,-0.21908496776221295,0.3073470949989358) .. (0.9276421250869806,-0.2243497502487427,0.2985754131328266) .. (0.9291504565400335,-0.22959047225380713,0.28977171042343275) .. (0.9305591408692842,-0.2348065717340142,0.280936931027481) .. (0.931868026999801,-0.23999748928662423,0.2720720224345305) .. (0.9330769745595511,-0.2451626682095444,0.263177935365358) .. (0.9341858538944549,-0.2503015545610314,0.2542556236699985);
 draw(p2, curveStyle2);
path3 p3 = (0.6391065469387733,0.0630132147194146,0.7665325540580271) .. (0.6397670227504347,0.06321750309125168,0.7659645578641039) .. (0.6404269863763171,0.06342174085231184,0.7653959484529628) .. (0.6410864372880657,0.06362592783908606,0.7648267262798223) .. (0.6417453749577363,0.06383006388810598,0.764256891800391) .. (0.6424037988577952,0.06403414883594404,0.7636864454708683) .. (0.6430617084611203,0.06423818251921351,0.7631153877479427) .. (0.6437191032410016,0.0644421647745688,0.762543719088793) .. (0.6443759826711403,0.06464609543870542,0.7619714399510863) .. (0.645032346225651,0.0648499743483602,0.761398550792979) .. (0.645688193379061,0.06505380134031145,0.7608250520731158) .. (0.6463435236063113,0.06525757625137898,0.760250944250629) .. (0.6469983363827563,0.06546129891842434,0.759676227785139) .. (0.6476526311841646,0.06566496917835088,0.7591009031367532) .. (0.6483064074867203,0.06586858686810389,0.7585249707660661) .. (0.6489596647670217,0.06607215182467081,0.7579484311341586) .. (0.6496124025020829,0.06627566388508124,0.7573712847025977) .. (0.6502646201693343,0.06647912288640717,0.7567935319334363) .. (0.650916317246622,0.066682528665763,0.7562151732892128) .. (0.6515674932122096,0.06688588106030581,0.7556362092329506) .. (0.6522181475447774,0.06708917990723538,0.7550566402281575) .. (0.6528682797234233,0.06729242504379439,0.7544764667388261) .. (0.6535178892276636,0.06749561630726848,0.7538956892294324) .. (0.6541669755374326,0.06769875353498646,0.7533143081649365) .. (0.6548155381330838,0.06790183656432036,0.7527323240107814) .. (0.6554635764953898,0.06810486523268564,0.7521497372328929) .. (0.6561110901055428,0.06830783937754123,0.7515665482976792) .. (0.6567580784451555,0.06851075883638978,0.7509827576720313) .. (0.6574045409962609,0.06871362344677766,0.7503983658233204) .. (0.6580504772413126,0.06891643304629518,0.7498133732194007) .. (0.658695886663186,0.06911918747257667,0.7492277803286059) .. (0.6593407687451781,0.06932188656330066,0.7486415876197516) .. (0.6599851229710082,0.06952453015618995,0.7480547955621326) .. (0.660628948824818,0.0697271180890118,0.747467404625524) .. (0.6612722457911723,0.06992965019957802,0.7468794152801803) .. (0.6619150133550593,0.07013212632574509,0.7462908279968348) .. (0.6625572510018911,0.07033454630541432,0.7457016432466999) .. (0.663198958217504,0.070536909976532,0.7451118615014659) .. (0.6638401344881588,0.07073921717708946,0.7445214832333017) .. (0.6644807793005417,0.07094146774512328,0.7439305089148531) .. (0.665120892141764,0.0711436615187153,0.7433389390192433) .. (0.6657604724993632,0.07134579833599292,0.7427467740200723) .. (0.6663995198613027,0.0715478780351291,0.7421540143914167) .. (0.6670380337159733,0.07174990045434254,0.741560660607829) .. (0.6676760135521922,0.07195186543189774,0.7409667131443375) .. (0.6683134588592043,0.07215377280610528,0.7403721724764453) .. (0.668950369126683,0.07235562241532179,0.7397770390801311) .. (0.669586743844729,0.07255741409795015,0.7391813134318478) .. (0.6702225825038729,0.07275914769243966,0.7385849960085223) .. (0.6708578845950735,0.07296082303728607,0.7379880872875556) .. (0.6714926496097195,0.07316243997103178,0.7373905877468218) .. (0.67212687703963,0.07336399833226598,0.736792497864668) .. (0.6727605663770541,0.07356549795962472,0.7361938181199145) .. (0.6733937171146714,0.07376693869179111,0.7355945489918528) .. (0.6740263287455932,0.07396832036749534,0.7349946909602469) .. (0.674658400763362,0.07416964282551496,0.7343942445053325) .. (0.6752899326619528,0.07437090590467488,0.7337932101078158) .. (0.6759209239357725,0.07457210944384754,0.7331915882488739) .. (0.6765513740796611,0.07477325328195308,0.7325893794101543) .. (0.6771812825888918,0.07497433725795942,0.7319865840737746) .. (0.6778106489591711,0.07517536121088243,0.7313832027223215) .. (0.6784394726866402,0.07537632497978597,0.730779235838851) .. (0.679067753267874,0.07557722840378216,0.7301746839068882) .. (0.6796954901998827,0.07577807132203135,0.7295695474104261) .. (0.6803226829801114,0.07597885357374241,0.7289638268339261) .. (0.6809493311064414,0.07617957499817272,0.7283575226623169) .. (0.6815754340771895,0.0763802354346284,0.7277506353809946) .. (0.682200991391109,0.07658083472246435,0.727143165475822) .. (0.68282600254739,0.07678137270108445,0.7265351134331282) .. (0.6834504670456605,0.07698184920994168,0.725926479739709) .. (0.6840743843859852,0.07718226408853819,0.7253172648828251) .. (0.6846977540688677,0.07738261717642551,0.7247074693502028) .. (0.6853205755952491,0.07758290831320462,0.7240970936300333) .. (0.6859428484665103,0.07778313733852608,0.7234861382109722) .. (0.6865645721844709,0.07798330409209024,0.7228746035821393) .. (0.68718574625139,0.0781834084136472,0.722262490233118) .. (0.6878063701699675,0.07838345014299714,0.721649798653955) .. (0.6884264434433428,0.07858342911999028,0.72103652933516) .. (0.6890459655750969,0.07878334518452715,0.7204226827677054) .. (0.6896649360692515,0.07898319817655856,0.7198082594430253) .. (0.6902833544302702,0.07918298793608589,0.7191932598530157) .. (0.6909012201630585,0.07938271430316109,0.7185776844900345) .. (0.6915185327729646,0.07958237711788689,0.7179615338468994) .. (0.6921352917657793,0.07978197622041691,0.7173448084168899) .. (0.6927514966477362,0.07998151145095572,0.7167275086937448) .. (0.6933671469255135,0.0801809826497591,0.716109635171663) .. (0.6939822421062325,0.08038038965713405,0.7154911883453028) .. (0.6945967816974593,0.08057973231343896,0.7148721687097815) .. (0.6952107652072049,0.08077901045908373,0.714252576760675) .. (0.6958241921439251,0.08097822393452994,0.7136324129940168) .. (0.6964370620165217,0.08117737258029092,0.713011677906299) .. (0.6970493743343421,0.08137645623693192,0.712390371994471) .. (0.6976611286071805,0.08157547474507018,0.7117684957559384) .. (0.6982723243452775,0.08177442794537512,0.7111460496885644) .. (0.6988829610593209,0.08197331567856846,0.7105230342906677) .. (0.6994930382604461,0.08217213778542432,0.7098994500610231) .. (0.7001025554602367,0.08237089410676937,0.7092752974988608) .. (0.700711512170724,0.0825695844834829,0.7086505771038657) .. (0.7013199079043887,0.08276820875649704,0.7080252893761778) .. (0.7019277421741603,0.08296676676679686,0.707399434816391);
 draw(p3, curveStyle3);

/*
  Exported tangent vectors
*/
draw( (0.7639620330594684,0.024619949473770695,0.6447913384433398)--(1.325059442310737,-0.5434485486929762,0.0016820485533789453), tVectorStyle1,Arrow3(6.0));
