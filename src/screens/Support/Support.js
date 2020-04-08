import React from 'react';
import {SafeAreaView, View, TextInput, TouchableOpacity} from 'react-native';
import AppText from '../../components/AppText';
import styles from './styles';

const Support = () => {
  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.inputField}>
        <TextInput
          placeholder={'Describe your problem here...'}
          style={styles.textInput}
        />
      </View>
      <View style={styles.buttons}>
        <TouchableOpacity style={styles.message}>
          <AppText style={styles.btnTxt}>Send Message</AppText>
        </TouchableOpacity>
        <TouchableOpacity style={styles.logs}>
          <AppText style={styles.btnTxt}>Logs</AppText>
        </TouchableOpacity>
      </View>
      <AppText style={styles.intro}>
        In this section you will find answers to the most popular questions that
        we receive from our customers.
      </AppText>
    </SafeAreaView>
  );
};
export default Support;
