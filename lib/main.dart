import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://kaufyqvgodcyagygzvyb.supabase.co';
const supabaseKey = 'sb_publishable_6IUFp0yT959c3HtlB94YrQ_DnvKClfF';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const GekoFleetApp());
}

final db = Supabase.instance.client;

class GekoFleetApp extends StatelessWidget {
  const GekoFleetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'GEKO Fleet',
    theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF16A34A),brightness:Brightness.dark),useMaterial3:true),
    home:db.auth.currentSession == null ? const LoginPage() : const CourierHome(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState()=>_LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email=TextEditingController(), password=TextEditingController();
  bool busy=false;
  Future<void> login() async {
    setState(()=>busy=true);
    try {
      await db.auth.signInWithPassword(email:email.text.trim(),password:password.text);
      if(mounted) Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const CourierHome()));
    } on AuthException catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.message)));
    } finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
    const Icon(Icons.local_shipping,size:72),const SizedBox(height:12),
    const Text('GEKO Fleet',style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),
    const SizedBox(height:32),
    TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'E-mail',border:OutlineInputBorder())),
    const SizedBox(height:14),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Hasło',border:OutlineInputBorder())),
    const SizedBox(height:20),
    SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:login,child:Text(busy?'Logowanie...':'Zaloguj się'))),
  ])))));
}

class CourierHome extends StatefulWidget {
  const CourierHome({super.key});
  @override State<CourierHome> createState()=>_CourierHomeState();
}
class _CourierHomeState extends State<CourierHome> {
  List<Map<String,dynamic>> vehicles=[];
  Map<String,dynamic>? selected;
  bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    try {
      final rows=await db.from('vehicles').select('id,registration,name,mileage,status').eq('status','active').order('registration');
      Map<String,dynamic>? current;
      final uid=db.auth.currentUser!.id;
      final sessions=await db.from('vehicle_sessions').select('vehicle_id,vehicles(id,registration,name,mileage,status)').eq('courier_id',uid).isFilter('ended_at',null).limit(1);
      if(sessions.isNotEmpty && sessions.first['vehicles']!=null) current=Map<String,dynamic>.from(sessions.first['vehicles']);
      if(mounted)setState((){vehicles=List<Map<String,dynamic>>.from(rows);selected=current;loading=false;});
    } catch(e){if(mounted){setState(()=>loading=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Błąd pobierania danych: $e')));}}
  }
  Future<void> choose(Map<String,dynamic> v) async {
    final uid=db.auth.currentUser!.id;
    await db.from('vehicle_sessions').update({'ended_at':DateTime.now().toUtc().toIso8601String()}).eq('courier_id',uid).isFilter('ended_at',null);
    await db.from('vehicle_sessions').insert({'courier_id':uid,'vehicle_id':v['id']});
    setState(()=>selected=v);
  }
  Future<void> logout() async {await db.auth.signOut();if(mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginPage()),(_)=>false);}
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('GEKO Fleet',style:TextStyle(fontWeight:FontWeight.bold)),actions:[IconButton(onPressed:logout,icon:const Icon(Icons.logout))]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Dzisiejszy pojazd',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:10),
      if(selected==null) const Card(child:ListTile(leading:Icon(Icons.info_outline),title:Text('Nie wybrano pojazdu'),subtitle:Text('Wybierz samochód, którym dzisiaj jedziesz.')))
      else Card(child:ListTile(leading:const Icon(Icons.local_shipping),title:Text('${selected!['registration']} • ${selected!['name']}',style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${selected!['mileage']} km'))),
      const SizedBox(height:20),
      if(selected!=null) SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>AddFaultPage(vehicle:selected!))),icon:const Icon(Icons.build),label:const Text('Zgłoś usterkę'))),
      const SizedBox(height:24),const Text('Wybierz pojazd',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const SizedBox(height:8),
      ...vehicles.map((v)=>Card(child:ListTile(leading:const Icon(Icons.directions_car),title:Text('${v['registration']} • ${v['name']}'),subtitle:Text('${v['mileage']} km'),trailing:selected?['id']==v['id']?const Icon(Icons.check_circle):const Icon(Icons.chevron_right),onTap:()=>choose(v)))),
    ])),
  );
}

class AddFaultPage extends StatefulWidget {
  const AddFaultPage({super.key,required this.vehicle});
  final Map<String,dynamic> vehicle;
  @override State<AddFaultPage> createState()=>_AddFaultPageState();
}
class _AddFaultPageState extends State<AddFaultPage> {
  final title=TextEditingController(),description=TextEditingController(); bool busy=false;
  Future<void> save() async {
    if(title.text.trim().length<2||description.text.trim().length<2){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Uzupełnij rodzaj i opis usterki')));return;}
    setState(()=>busy=true);
    try {
      await db.from('faults').insert({'vehicle_id':widget.vehicle['id'],'reported_by':db.auth.currentUser!.id,'title':title.text.trim(),'description':description.text.trim()});
      if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Usterka została zgłoszona')));Navigator.pop(context);}
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Nie udało się zapisać: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Zgłoś usterkę')),body:ListView(padding:const EdgeInsets.all(16),children:[
    Card(child:ListTile(leading:const Icon(Icons.local_shipping),title:Text('${widget.vehicle['registration']} • ${widget.vehicle['name']}'))),const SizedBox(height:16),
    TextField(controller:title,decoration:const InputDecoration(labelText:'Rodzaj usterki',hintText:'np. nie działa lewe światło',border:OutlineInputBorder())),const SizedBox(height:16),
    TextField(controller:description,minLines:5,maxLines:10,decoration:const InputDecoration(labelText:'Opis usterki',hintText:'Opisz dokładnie problem i kiedy występuje',alignLabelWithHint:true,border:OutlineInputBorder())),const SizedBox(height:20),
    FilledButton.icon(onPressed:busy?null:save,icon:const Icon(Icons.send),label:Text(busy?'Zapisywanie...':'Wyślij zgłoszenie')),
  ]));
}
