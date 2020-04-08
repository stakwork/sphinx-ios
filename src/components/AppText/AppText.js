import React from 'react';
import styles from './styles';
import {Text} from 'react-native';

const AppText = (props) => {
  return (
    <Text style={{...styles.defaultFont, ...props.style}}>
      {props.children}
    </Text>
  );
};

export default AppText;
