import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl='https://kaufyqvgodcyagygzvyb.supabase.co';
const supabaseKey='sb_publishable_6IUFp0yT959c3HtlB94YrQ_DnvKClfF';

Future<void> main() async {WidgetsFlutterBinding.ensureInitialized();await Supabase.initialize(url:supabaseUrl,anonKey:supabaseKey);runApp(const GekoFleetApp());}
final db=Supabase.instance.client;

class GekoFleetApp extends StatelessWidget{
 const GekoFleetApp({super.key});
 @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'GEKO Fleet',theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF16A34A),brightness:Brightness.dark),useMaterial3:true),home:db.auth.currentSession==null?const LoginPage():const CourierHome());
}

class LoginPage extends StatefulWidget{const LoginPage({super.key});@override State<LoginPage> createState()=>_LoginPageState();}
class _LoginPageState extends State<LoginPage>{
 final email=TextEditingController(),password=TextEditingController();bool busy=false;
 Future<void> login()async{setState(()=>busy=true);try{await db.auth.signInWithPassword(email:email.text.trim(),password:password.text);if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const CourierHome()));}on AuthException catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.local_shipping,size:72),const SizedBox(height:12),const Text('GEKO Fleet',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:32),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail',border:OutlineInputBorder())),const SizedBox(height:14),TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Hasło',border:OutlineInputBorder())),const SizedBox(height:20),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:login,child:Text(busy?'Logowanie...':'Zaloguj się')))])))));
}

class CourierHome extends StatefulWidget{const CourierHome({super.key});@override State<CourierHome> createState()=>_CourierHomeState();}
class _CourierHomeState extends State<CourierHome>{
 List<Map<String,dynamic>> vehicles=[];Map<String,dynamic>? selected;bool loading=true;
 @override void initState(){super.initState();load();}
 Future<void> load()async{try{final rows=await db.from('vehicles').select('id,registration,name,mileage,status,vin,production_year,fuel_type,inspection_due,insurance_due').eq('status','active').order('registration');Map<String,dynamic>? current;final uid=db.auth.currentUser!.id;final sessions=await db.from('vehicle_sessions').select('vehicle_id,vehicles(id,registration,name,mileage,status,vin,production_year,fuel_type,inspection_due,insurance_due)').eq('courier_id',uid).isFilter('ended_at',null).limit(1);if(sessions.isNotEmpty&&sessions.first['vehicles']!=null)current=Map<String,dynamic>.from(sessions.first['vehicles']);if(mounted)setState((){vehicles=List<Map<String,dynamic>>.from(rows);selected=current;loading=false;});}catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Błąd pobierania danych: $e')));}}}
 Future<void> choose(Map<String,dynamic> v)async{final uid=db.auth.currentUser!.id;await db.from('vehicle_sessions').update({'ended_at':DateTime.now().toUtc().toIso8601String()}).eq('courier_id',uid).isFilter('ended_at',null);await db.from('vehicle_sessions').insert({'courier_id':uid,'vehicle_id':v['id']});setState(()=>selected=v);}
 Future<void> logout()async{await db.auth.signOut();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('GEKO Fleet',style:TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
 const Text('Dzisiejszy pojazd',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:10),
 if(selected==null)const Card(child:ListTile(leading:Icon(Icons.info_outline),title:Text('Nie wybrano pojazdu'),subtitle:Text('Wybierz samochód, którym dzisiaj jedziesz.')))else Card(child:ListTile(leading:const Icon(Icons.local_shipping),title:Text("${selected!['registration']} • ${selected!['name']}",style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text("${selected!['mileage']} km"))),
 const SizedBox(height:16),
 if(selected!=null)...[
 SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>VehicleCheckPage(vehicle:selected!))),icon:const Icon(Icons.fact_check),label:const Text('Kontrola przed wyjazdem'))),
 const SizedBox(height:10),
 SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AddFaultPage(vehicle:selected!))),icon:const Icon(Icons.build),label:const Text('Zgłoś usterkę / uszkodzenie'))),
 ],
 const SizedBox(height:24),const Text('Wybierz pojazd',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),
 ...vehicles.map((v)=>Card(child:ListTile(leading:const Icon(Icons.directions_car),title:Text("${v['registration']} • ${v['name']}"),trailing:Wrap(mainAxisSize:MainAxisSize.min,children:[if(selected?['id']==v['id'])const Icon(Icons.check_circle),IconButton(icon:const Icon(Icons.info_outline),onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>VehicleDetailsPage(vehicle:v))))]),onTap:()=>choose(v))))
 ])));
}

class PhotoPicker extends StatelessWidget{
 const PhotoPicker({super.key,required this.photos,required this.onAdd,required this.onRemove});
 final List<XFile> photos; final Future<void> Function(ImageSource) onAdd; final void Function(int) onRemove;
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Wrap(spacing:8,runSpacing:8,children:[
   OutlinedButton.icon(onPressed:()=>onAdd(ImageSource.camera),icon:const Icon(Icons.photo_camera),label:const Text('Zrób zdjęcie')),
   OutlinedButton.icon(onPressed:()=>onAdd(ImageSource.gallery),icon:const Icon(Icons.photo_library),label:const Text('Galeria')),
  ]),
  if(photos.isNotEmpty)...[const SizedBox(height:8),...List.generate(photos.length,(i)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.image),title:Text('Zdjęcie ${i+1}'),subtitle:Text(photos[i].name,overflow:TextOverflow.ellipsis),trailing:IconButton(icon:const Icon(Icons.close),onPressed:()=>onRemove(i))))],
 ]);
}

Future<List<String>> uploadVehiclePhotos(List<XFile> photos,String kind)async{
 final uid=db.auth.currentUser!.id; final paths=<String>[];
 for(var i=0;i<photos.length;i++){
  final Uint8List bytes=await photos[i].readAsBytes();
  final ext=photos[i].name.contains('.')?photos[i].name.split('.').last.toLowerCase():'jpg';
  final path='$uid/$kind/${DateTime.now().microsecondsSinceEpoch}_$i.$ext';
  await db.storage.from('vehicle-photos').uploadBinary(path,bytes,fileOptions:const FileOptions(upsert:false));
  paths.add(path);
 }
 return paths;
}

class VehicleDetailsPage extends StatelessWidget{
 const VehicleDetailsPage({super.key,required this.vehicle});
 final Map<String,dynamic> vehicle;
 String value(String key)=>vehicle[key]?.toString().trim().isNotEmpty==true?vehicle[key].toString():'—';
 @override Widget build(BuildContext context)=>Scaffold(
  appBar:AppBar(title:Text(value('registration'))),
  body:SafeArea(top:false,child:ListView(padding:const EdgeInsets.all(16),children:[
   Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Icon(Icons.local_shipping,size:42),
    const SizedBox(height:10),
    Text(value('registration'),style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
    Text(value('name'),style:const TextStyle(fontSize:18)),
   ]))),
   const SizedBox(height:12),
   _VehicleField(label:'VIN',value:value('vin')),
   _VehicleField(label:'Rok produkcji',value:value('production_year')),
   _VehicleField(label:'Rodzaj paliwa',value:value('fuel_type')),
   _VehicleField(label:'Badanie techniczne do',value:value('inspection_due')),
   _VehicleField(label:'OC do',value:value('insurance_due')),
   _VehicleField(label:'Status',value:value('status')),
  ]))
 );
}
class _VehicleField extends StatelessWidget{
 const _VehicleField({required this.label,required this.value});final String label,value;
 @override Widget build(BuildContext context)=>Card(child:ListTile(title:Text(label),subtitle:Text(value,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w600))));
}

class VehicleCheckPage extends StatefulWidget{const VehicleCheckPage({super.key,required this.vehicle});final Map<String,dynamic> vehicle;@override State<VehicleCheckPage> createState()=>_VehicleCheckPageState();}
class _VehicleCheckPageState extends State<VehicleCheckPage>{
 final note=TextEditingController();bool busy=false;final picker=ImagePicker();final List<XFile> photos=[];
 final Map<String,bool> checks={'Poziom oleju':true,'Płyn chłodniczy':true,'Płyn do spryskiwaczy':true,'Opony':true,'Światła':true,'Nadwozie – widoczne uszkodzenia':true,'Kontrolki na desce':true};
 bool get hasProblem=>checks.values.any((v)=>!v);
 bool get bodyProblem=>checks['Nadwozie – widoczne uszkodzenia']==false;
 Future<void> addPhoto(ImageSource source)async{final p=await picker.pickImage(source:source,imageQuality:75,maxWidth:1600);if(p!=null&&mounted)setState(()=>photos.add(p));}
 Future<void> save()async{
  if(hasProblem&&note.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Przy wykrytym problemie dodaj krótki opis.')));return;}
  if(bodyProblem&&photos.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Przy uszkodzeniu nadwozia dodaj co najmniej jedno zdjęcie.')));return;}
  setState(()=>busy=true);
  try{
   final uid=db.auth.currentUser!.id;final sessions=await db.from('vehicle_sessions').select('id').eq('courier_id',uid).eq('vehicle_id',widget.vehicle['id']).isFilter('ended_at',null).limit(1);
   final photoPaths=await uploadVehiclePhotos(photos,'checks');
   await db.from('vehicle_checks').insert({'vehicle_id':widget.vehicle['id'],'courier_id':uid,'session_id':sessions.isEmpty?null:sessions.first['id'],'engine_oil_ok':checks['Poziom oleju'],'coolant_ok':checks['Płyn chłodniczy'],'washer_fluid_ok':checks['Płyn do spryskiwaczy'],'tires_ok':checks['Opony'],'lights_ok':checks['Światła'],'body_ok':checks['Nadwozie – widoczne uszkodzenia'],'dashboard_ok':checks['Kontrolki na desce'],'note':note.text.trim().isEmpty?null:note.text.trim(),'photo_paths':photoPaths});
   if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Kontrola została zapisana')));Navigator.pop(context);}
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Nie udało się zapisać kontroli: $e')));}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Kontrola przed wyjazdem')),body:SafeArea(top:false,child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,32),children:[
  Card(child:ListTile(leading:const Icon(Icons.local_shipping),title:Text("${widget.vehicle['registration']} • ${widget.vehicle['name']}"))),
  const SizedBox(height:10),const Text('Sprawdź każdy punkt. Jeśli coś jest nie tak, wybierz „Problem”.',style:TextStyle(fontSize:16)),const SizedBox(height:12),
  ...checks.keys.map((k)=>Card(child:ListTile(title:Text(k,style:const TextStyle(fontWeight:FontWeight.w600)),trailing:SegmentedButton<bool>(segments:const [ButtonSegment(value:true,label:Text('OK'),icon:Icon(Icons.check)),ButtonSegment(value:false,label:Text('Problem'),icon:Icon(Icons.warning_amber))],selected:{checks[k]!},onSelectionChanged:(s)=>setState(()=>checks[k]=s.first))))),
  if(hasProblem)...[const SizedBox(height:12),TextField(controller:note,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'Krótki opis problemu *',hintText:'Co zauważyłeś?',border:OutlineInputBorder())),const SizedBox(height:12),Text(bodyProblem?'Zdjęcie uszkodzenia nadwozia jest obowiązkowe.':'Zdjęcie problemu jest opcjonalne.',style:TextStyle(color:bodyProblem?Colors.orangeAccent:null)),const SizedBox(height:8),PhotoPicker(photos:photos,onAdd:addPhoto,onRemove:(i)=>setState(()=>photos.removeAt(i)))],
  const SizedBox(height:18),FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.save),label:Text(busy?'Zapisywanie...':'Zapisz kontrolę'))
 ])));
}

class AddFaultPage extends StatefulWidget{const AddFaultPage({super.key,required this.vehicle});final Map<String,dynamic> vehicle;@override State<AddFaultPage> createState()=>_AddFaultPageState();}
class _AddFaultPageState extends State<AddFaultPage>{
 final title=TextEditingController(),description=TextEditingController();bool busy=false;final picker=ImagePicker();final List<XFile> photos=[];
 Future<void> addPhoto(ImageSource source)async{if(photos.length>=5){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Możesz dodać maksymalnie 5 zdjęć.')));return;}final p=await picker.pickImage(source:source,imageQuality:75,maxWidth:1600);if(p!=null&&mounted)setState(()=>photos.add(p));}
 Future<void> save()async{if(title.text.trim().length<2||description.text.trim().length<2){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Uzupełnij rodzaj i opis usterki')));return;}setState(()=>busy=true);try{final photoPaths=await uploadVehiclePhotos(photos,'faults');await db.from('faults').insert({'vehicle_id':widget.vehicle['id'],'reported_by':db.auth.currentUser!.id,'title':title.text.trim(),'description':description.text.trim(),'photo_paths':photoPaths});if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Usterka została zgłoszona')));Navigator.pop(context);}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Nie udało się zapisać: $e')));}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Zgłoś usterkę')),body:SafeArea(top:false,child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,32),children:[Card(child:ListTile(leading:const Icon(Icons.local_shipping),title:Text("${widget.vehicle['registration']} • ${widget.vehicle['name']}"))),const SizedBox(height:16),TextField(controller:title,decoration:const InputDecoration(labelText:'Rodzaj usterki',hintText:'np. uszkodzony zderzak',border:OutlineInputBorder())),const SizedBox(height:16),TextField(controller:description,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Krótki opis',hintText:'Opisz problem lub uszkodzenie',alignLabelWithHint:true,border:OutlineInputBorder())),const SizedBox(height:12),const Text('Zdjęcia uszkodzenia (opcjonalnie, maks. 5)',style:TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),PhotoPicker(photos:photos,onAdd:addPhoto,onRemove:(i)=>setState(()=>photos.removeAt(i))),const SizedBox(height:20),FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.send),label:Text(busy?'Zapisywanie...':'Wyślij zgłoszenie'))])));
}}
