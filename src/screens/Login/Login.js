import React from 'react';
import {View, Image, TouchableOpacity} from 'react-native';
import AppText from '../../components/AppText';
import styles from './styles';

const Login = () => {
  return (
    <View style={styles.container}>
      <View style={styles.splash}>
        <Image source={require('../../assets/images/loginSplash.png')} />
      </View>
      <View style={styles.logo}>
        <Image source={require('../../assets/images/TClogo2.png')} />
      </View>

      <View style={styles.textContainer}>
        <AppText style={styles.text}>
          Please login using your credentials and enjoy our technology for
          cryptocurrencies
        </AppText>
      </View>
      <TouchableOpacity style={styles.button}>
        <AppText style={styles.login}>Login</AppText>
      </TouchableOpacity>
      <View style={styles.signupContainer}>
        <AppText style={styles.question}>New here? </AppText>
        <TouchableOpacity>
          <AppText style={styles.signup}>Sign Up</AppText>
        </TouchableOpacity>
      </View>
    </View>
  );
};
export default Login;
