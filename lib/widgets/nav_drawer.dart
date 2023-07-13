import 'package:flutter/material.dart';
import 'package:rider_app/methods/auth_methods.dart';
import 'package:rider_app/models/users.dart';
import 'package:rider_app/screens/home_screen.dart';
import 'package:rider_app/screens/login_screen.dart';
import 'package:rider_app/utils/dimensions.dart';

class NavDrawer extends StatelessWidget {
  final Users? currentUser;
  const NavDrawer({Key? key, required this.currentUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height*0.35,
            child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.yellow.shade300
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: MediaQuery.of(context).size.height*0.09,
                      child: Image.asset('images/user_icon.png',),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height*0.02 ,),
                    Text((currentUser == null) ? 'User name' : currentUser!.username, style: TextStyle(
                      fontFamily: 'Brand bold',
                      fontSize: MediaQuery.of(context).size.width*headingThreeSize
                    ),),
                    SizedBox(height: MediaQuery.of(context).size.height*0.01,),
                    Text((currentUser == null) ? 'E-mail' : currentUser!.email,),
                  ],
                )),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('History',style: TextStyle(fontSize: MediaQuery.of(context).size.width*textFieldTextSize),),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('Visit Profile',style: TextStyle(fontSize: MediaQuery.of(context).size.width*textFieldTextSize),),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('Log Out', style: TextStyle(fontSize: MediaQuery.of(context).size.width*textFieldTextSize),),
            onTap: () {
              AuthMethods().logOut();
              Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
            },
          )
        ],
      ),
    );
  }
}
