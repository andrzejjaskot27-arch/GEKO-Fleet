import 'package:flutter/material.dart';

void main() => runApp(const GekoFleetApp());

class Vehicle {
  Vehicle(this.name, this.reg, this.mileage, {this.driver='Nieprzypisany', this.status='Sprawny'});
  final String name, reg;
  int mileage;
  String driver, status;
}

class GekoFleetApp extends StatelessWidget {
  const GekoFleetApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'GEKO Fleet',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A), brightness: Brightness.dark),
      useMaterial3: true,
    ),
    home: const FleetShell(),
  );
}

class FleetShell extends StatefulWidget {
  const FleetShell({super.key});
  @override State<FleetShell> createState()=>_FleetShellState();
}

class _FleetShellState extends State<FleetShell> {
  int index=0;
  final vehicles=<Vehicle>[
    Vehicle('Renault Master 2.3','DW 4GEKO',351240,driver:'M. Kowalski'),
    Vehicle('Ford Transit','DW 7GEKO',228500,driver:'A. Nowak',status:'Usterka'),
    Vehicle('Opel Movano','DW 2GEKO',194820,driver:'P. Wiśniewski'),
  ];
  final faults=<Fault>[Fault('DW 7GEKO','Hamulce / zawieszenie','Auto ściąga przy hamowaniu','A. Nowak')];
  final costs=<double>[];
  final inspections=<String,String>{};

  @override Widget build(BuildContext context) {
    final pages=[
      Dashboard(vehicles:vehicles,faults:faults,costs:costs),
      FleetPage(vehicles:vehicles,onChanged:()=>setState((){})),
      FaultPage(faults:faults,vehicles:vehicles,onChanged:()=>setState((){})),
      CostPage(costs:costs,onAdd:()=>setState(()=>costs.add(250))),
      MorePage(vehicles:vehicles,inspections:inspections,onChanged:()=>setState((){})),
    ];
    return Scaffold(
      appBar:AppBar(title:const Text('GEKO Fleet',style:TextStyle(fontWeight:FontWeight.w800))),
      body:pages[index],
      bottomNavigationBar:NavigationBar(
        selectedIndex:index,onDestinationSelected:(i)=>setState(()=>index=i),
        destinations:const [
          NavigationDestination(icon:Icon(Icons.dashboard_outlined),label:'Start'),
          NavigationDestination(icon:Icon(Icons.local_shipping_outlined),label:'Flota'),
          NavigationDestination(icon:Icon(Icons.build_outlined),label:'Usterki'),
          NavigationDestination(icon:Icon(Icons.payments_outlined),label:'Koszty'),
          NavigationDestination(icon:Icon(Icons.more_horiz),label:'Więcej'),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key,required this.vehicles,required this.faults,required this.costs});
  final List<Vehicle> vehicles; final List<Fault> faults; final List<double> costs;
  @override Widget build(BuildContext c) {
    final total=costs.fold<double>(0,(a,b)=>a+b);
    return ListView(padding:const EdgeInsets.all(16),children:[
      const Text('Dzień dobry 👋',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),
      const Text('Stan floty GEKO GROUP'),const SizedBox(height:16),
      GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.5,children:[
        Stat('Pojazdy','${vehicles.length}',Icons.local_shipping),
        Stat('Usterki','${faults.length}',Icons.warning_amber),
        Stat('Wyłączone','${vehicles.where((v)=>v.status!='Sprawny').length}',Icons.car_crash),
        Stat('Koszty','${total.toStringAsFixed(0)} zł',Icons.payments),
      ]),
      const SizedBox(height:18),const Text('Wymaga uwagi',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
      ...vehicles.where((v)=>v.status!='Sprawny').map((v)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text('${v.reg} • ${v.name}'),subtitle:Text(v.status)))),
    ]);
  }
}
class Stat extends StatelessWidget {
  const Stat(this.label,this.value,this.icon,{super.key}); final String label,value; final IconData icon;
  @override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon),const Spacer(),Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(label)])));
}

class FleetPage extends StatelessWidget {
  const FleetPage({super.key,required this.vehicles,required this.onChanged}); final List<Vehicle> vehicles; final VoidCallback onChanged;
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(12),children:[
    ...vehicles.map((v)=>Card(child:ListTile(
      leading:CircleAvatar(child:Icon(v.status=='Sprawny'?Icons.local_shipping:Icons.warning_amber)),
      title:Text('${v.name} • ${v.reg}',style:const TextStyle(fontWeight:FontWeight.bold)),
      subtitle:Text('${v.mileage} km\n${v.driver}'),isThreeLine:true,
      trailing:PopupMenuButton<String>(onSelected:(x){v.status=x;onChanged();},itemBuilder:(_)=>['Sprawny','Usterka','Serwis'].map((x)=>PopupMenuItem(value:x,child:Text(x))).toList()),
    )))
  ]);
}

class FaultPage extends StatelessWidget {
  const FaultPage({super.key,required this.faults,required this.onAdd}); final List<String> faults; final VoidCallback onAdd;
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
    Row(children:[const Expanded(child:Text('Usterki',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold))),FilledButton.icon(onPressed:onAdd,icon:const Icon(Icons.add),label:const Text('Zgłoś'))]),
    const SizedBox(height:12),...faults.map((f)=>Card(child:ListTile(leading:const Icon(Icons.warning_amber),title:Text(f),subtitle:const Text('Do weryfikacji przez koordynatora'))))
  ]);
}

class CostPage extends StatelessWidget {
  const CostPage({super.key,required this.costs,required this.onAdd}); final List<double> costs; final VoidCallback onAdd;
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Koszty',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),
    ...costs.asMap().entries.map((e)=>Card(child:ListTile(title:Text('Koszt #${e.key+1}'),trailing:Text('${e.value.toStringAsFixed(2)} zł')))),
    FilledButton.icon(onPressed:onAdd,icon:const Icon(Icons.add),label:const Text('Dodaj koszt testowy'))
  ]);
}

class MorePage extends StatelessWidget {
  const MorePage({super.key,required this.vehicles,required this.inspections,required this.onChanged});
  final List<Vehicle> vehicles; final Map<String,String> inspections; final VoidCallback onChanged;
  @override Widget build(BuildContext c)=>ListView(children:[
    ListTile(leading:const Icon(Icons.fact_check_outlined),title:const Text('Kontrola przed wyjazdem'),subtitle:const Text('Płyny • światła • opony • hamulce • uszkodzenia'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>InspectionPage(vehicles:vehicles,inspections:inspections,onChanged:onChanged)))),
    ListTile(leading:const Icon(Icons.monitor_heart_outlined),title:const Text('Panel koordynatora'),subtitle:const Text('OK • uwaga • krytyczna • brak kontroli'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoordinatorPage(vehicles:vehicles,inspections:inspections)))),
    const Divider(),
    const ListTile(leading:Icon(Icons.people_outline),title:Text('Kierowcy')),
    const ListTile(leading:Icon(Icons.event_outlined),title:Text('Terminy i przypomnienia')),
    const ListTile(leading:Icon(Icons.tire_repair),title:Text('Opony')),
    const ListTile(leading:Icon(Icons.description_outlined),title:Text('Dokumenty i faktury')),
  ]);
}

class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key,required this.vehicles,required this.inspections,required this.onChanged});
  final List<Vehicle> vehicles; final Map<String,String> inspections; final VoidCallback onChanged;
  @override State<InspectionPage> createState()=>_InspectionPageState();
}
class _InspectionPageState extends State<InspectionPage> {
  late String reg=widget.vehicles.first.reg; String result='OK';
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Kontrola przed wyjazdem')),body:ListView(padding:const EdgeInsets.all(16),children:[
    DropdownButtonFormField<String>(value:reg,items:widget.vehicles.map((v)=>DropdownMenuItem(value:v.reg,child:Text('${v.reg} • ${v.name}'))).toList(),onChanged:(v)=>setState(()=>reg=v!)),
    const SizedBox(height:16),
    ...['Poziom oleju i płynów','Światła','Opony','Hamulce','Szyby i lusterka','Kontrolki','Karoseria','Wyposażenie'].map((x)=>CheckboxListTile(value:true,onChanged:(_){},title:Text(x))),
    const SizedBox(height:12),
    SegmentedButton<String>(segments:const [ButtonSegment(value:'OK',label:Text('OK')),ButtonSegment(value:'Uwaga',label:Text('Uwaga')),ButtonSegment(value:'Krytyczna',label:Text('Krytyczna'))],selected:{result},onSelectionChanged:(s)=>setState(()=>result=s.first)),
    const SizedBox(height:16),
    FilledButton(onPressed:(){widget.inspections[reg]=result;widget.onChanged();Navigator.pop(c);},child:const Text('Zapisz kontrolę')),
  ]));
}

class CoordinatorPage extends StatelessWidget {
  const CoordinatorPage({super.key,required this.vehicles,required this.inspections}); final List<Vehicle> vehicles; final Map<String,String> inspections;
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Panel koordynatora')),body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Stan kontroli dzisiaj',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    ...vehicles.map((v){final s=inspections[v.reg]??'Brak kontroli';return Card(child:ListTile(leading:Icon(s=='OK'?Icons.check_circle:s=='Krytyczna'?Icons.error:Icons.warning_amber),title:Text('${v.reg} • ${v.name}'),subtitle:Text('${v.driver}\n$s'),isThreeLine:true));})
  ]));
}
