import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
  },
  splash: {paddingTop: 106},
  logo: {paddingTop: 69.64},
  textContainer: {
    width: 303,
    paddingTop: 31.79,
  },
  text: {
    fontSize: 14,
    textAlign: 'center',
    lineHeight: 21,
    color: '#9598AD',
  },
  button: {
    marginTop: 50,
    width: 327,
    height: 60,
    borderRadius: 12,
    backgroundColor: '#6977F7',
    justifyContent: 'center',
    shadowColor: 'rgb(105, 119, 247)',
    shadowOffset: {
      width: 0,
      height: 10,
    },
    elevation: 25,
    shadowOpacity: 0.2,
  },
  login: {
    fontSize: 18,
    color: '#FFF',
    fontWeight: '500',
    textAlign: 'center',
  },
  signupContainer: {flexDirection: 'row', marginTop: 20},
  question: {color: '#9598AD', fontSize: 16},
  signup: {color: '#343D9E', fontSize: 16, fontWeight: '500'},
});

export default styles;
