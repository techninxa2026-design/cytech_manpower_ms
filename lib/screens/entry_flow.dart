import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/cytech_theme.dart';

class EntryFlow extends StatefulWidget{
  const EntryFlow({super.key,required this.store});
  final AppStore store;
  @override State<EntryFlow> createState()=>_EntryFlowState();
}
class _EntryFlowState extends State<EntryFlow>{
  String step='splash';
  final username=TextEditingController();
  final password=TextEditingController();
  final confirmation=TextEditingController();
  @override void dispose(){username.dispose();password.dispose();confirmation.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    return switch(step){
      'login'=>_auth(false),
      'register'=>_auth(true),
      _=>_splash(),
    };
  }
  Widget _splash()=>Scaffold(backgroundColor:cyNavy,body:SafeArea(child:LayoutBuilder(
    builder:(context,bounds)=>SingleChildScrollView(child:ConstrainedBox(
      constraints:BoxConstraints(minHeight:bounds.maxHeight),
      child:Padding(padding:const EdgeInsets.symmetric(horizontal:25,vertical:24),child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,children:[
          const BrandLockup(dark:true),
          SizedBox(height:bounds.maxHeight<700?40:80),
          SizedBox(height:255,child:Stack(alignment:Alignment.center,children:[
            Positioned(top:15,child:Container(width:226,height:226,
              decoration:BoxDecoration(shape:BoxShape.circle,
                gradient:RadialGradient(colors:[cyOrange.withValues(alpha:.78),cyOrange.withValues(alpha:.09)])))),
            Transform.rotate(angle:-.10,child:Container(width:251,height:145,padding:const EdgeInsets.all(17),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(23),
                boxShadow:const [BoxShadow(color:Color(0x45000000),blurRadius:28,offset:Offset(0,16))]),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[
                  const Icon(Icons.groups_2_rounded,color:cyOrange),
                  const SizedBox(width:9),
                  const Expanded(child:Text('Site Operations',style:TextStyle(
                    color:cyNavy,fontSize:15,fontWeight:FontWeight.w900))),
                  const Icon(Icons.check_circle,color:Color(0xFF18A06A),size:17)
                ]),
                const SizedBox(height:11),
                const Text('TEAM DEPLOYED',style:TextStyle(
                  color:cyMuted,fontWeight:FontWeight.w800,letterSpacing:1.2,fontSize:9)),
                const SizedBox(height:10),
                Row(children:[
                  for(final id in ['ayesha','fahim','nabila'])
                    Padding(padding:const EdgeInsets.only(right:5),
                      child:PersonAvatar(widget.store.person(id),size:30)),
                  const Spacer(),
                  const Text('06 ACTIVE',style:TextStyle(
                    color:cyOrange,fontSize:11,fontWeight:FontWeight.w900))
                ])
              ]))),
            Positioned(bottom:0,right:0,child:Transform.rotate(angle:.09,child:Container(
              width:205,padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(color:const Color(0xFF183951),
                border:Border.all(color:Colors.white24),borderRadius:BorderRadius.circular(16)),
              child:const Row(children:[
                Icon(Icons.fact_check_rounded,color:cyOrange,size:24),SizedBox(width:10),
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('Attendance posted',style:TextStyle(color:Colors.white,
                    fontSize:12,fontWeight:FontWeight.w900)),
                  Text('Official team notice',style:TextStyle(
                    color:Color(0xFFAABDD0),fontSize:10))
                ]))
              ])))),
          ])),
          const SizedBox(height:35),
          const Text('YOUR PEOPLE.\nONE POWERFUL\nWORKSPACE.',style:TextStyle(
            color:Colors.white,fontSize:33,height:1.12,letterSpacing:-1.6,fontWeight:FontWeight.w900)),
          const SizedBox(height:13),
          const Text('Manage teams, coordinate on-site groups and keep important updates in focus.',
            style:TextStyle(color:Color(0xFFBDD0DF),height:1.7,fontSize:13)),
          const SizedBox(height:25),
          SizedBox(width:double.infinity,child:FilledButton(
            onPressed:()=>setState(()=>step='register'),
            child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text('GET STARTED'),SizedBox(width:10),Icon(Icons.arrow_forward_rounded,size:18)
            ]))),
          const SizedBox(height:10),
          SizedBox(width:double.infinity,child:OutlinedButton(
            style:OutlinedButton.styleFrom(foregroundColor:Colors.white,
              side:const BorderSide(color:Colors.white30)),
            onPressed:()=>setState(()=>step='login'),child:const Text('I ALREADY HAVE AN ACCOUNT'))),
        ])),
      )))));
  Widget _auth(bool register)=>Scaffold(body:SafeArea(child:SingleChildScrollView(
    padding:const EdgeInsets.fromLTRB(25,22,25,30),child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
        IconButton(onPressed:()=>setState(()=>step='splash'),
          icon:const Icon(Icons.arrow_back_ios_new_rounded,size:19),
          style:IconButton.styleFrom(backgroundColor:Colors.white)),
        const SizedBox(height:20),
        const BrandMark(size:58),
        const SizedBox(height:26),
        Text(register?'JOIN THE WORKFORCE':'WELCOME BACK',
          style:const TextStyle(color:cyOrange,fontSize:11,letterSpacing:1.8,fontWeight:FontWeight.w900)),
        const SizedBox(height:10),
        Text(register?'Create account.':'Sign in to Cytech.',
          style:const TextStyle(color:cyNavy,fontSize:31,fontWeight:FontWeight.w900,letterSpacing:-1.5)),
        const SizedBox(height:8),
        Text(register?'Join the Cytech manpower community and start collaborating.':
          'All your teams, groups and site updates in one place.',
          style:const TextStyle(fontSize:13,color:cyMuted,height:1.6)),
        const SizedBox(height:21),
        const FormLabel('Username'),
        TextField(key:const Key('auth_username'),controller:username,
          textInputAction:TextInputAction.next,
          decoration:const InputDecoration(prefixIcon:Icon(Icons.person_outline_rounded),
            hintText:'Enter username')),
        const FormLabel('Password'),
        TextField(key:const Key('auth_password'),controller:password,obscureText:true,
          decoration:const InputDecoration(prefixIcon:Icon(Icons.lock_outline_rounded),
            hintText:'Enter password')),
        if(register)...[
          const FormLabel('Confirm password'),
          TextField(controller:confirmation,obscureText:true,
            decoration:const InputDecoration(prefixIcon:Icon(Icons.verified_user_outlined),
              hintText:'Repeat password')),
        ],
        const SizedBox(height:26),
        SizedBox(width:double.infinity,child:FilledButton(
          key:Key(register?'register_continue':'login_continue'),
          onPressed:(){
            widget.store.enter(username:username.text,registering:register);
          },
          child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            Text(register?'CREATE ACCOUNT':'SIGN IN'),
            const SizedBox(width:9),const Icon(Icons.arrow_forward_rounded,size:17)
          ]))),
        const SizedBox(height:17),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          Text(register?'Already a member?':'New to Cytech?',
            style:const TextStyle(color:cyMuted,fontSize:12)),
          TextButton(onPressed:()=>setState(()=>step=register?'login':'register'),
            child:Text(register?'Sign in':'Register'))
        ]),
        const SizedBox(height:19),
        const InfoBanner('Preview mode: authentication is intentionally bypassed. '
          'Any sign-in continues to the workspace, while registration creates a local regular-member demo account.',
          color:cyNavy),
        const SizedBox(height:14),
        if(!register)CyCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('QUICK DEMO ACCESS',style:TextStyle(color:cyOrange,fontSize:10,
            fontWeight:FontWeight.w900,letterSpacing:1.1)),
          const SizedBox(height:10),
          Wrap(spacing:7,runSpacing:7,children:[
            for(final p in [
              ('admin','Admin'),('ayesha','Supervisor'),('fahim','Engineer'),('rafi','Member')
            ])ActionChip(label:Text(p.$2),onPressed:()=>widget.store.enter(username:p.$1)),
          ])
        ])),
      ]))));
}
