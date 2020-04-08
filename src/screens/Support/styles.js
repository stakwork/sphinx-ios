import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  inputField: {alignSelf: 'center', marginTop: 122},
  textInput: {
    width: 327,
    height: 33,
    fontSize: 16,
    fontFamily: 'GTWalsheimPro-Regular',
    borderBottomWidth: 1,
    borderBottomColor: '#E4E8EE',
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingTop: 26,
    paddingBottom: 46,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  message: {
    width: 191,
    height: 50,
    borderRadius: 12,
    backgroundColor: '#6977F7',
    justifyContent: 'center',
  },
  logs: {
    width: 120,
    height: 50,
    borderRadius: 12,
    backgroundColor: '#343D9E',
    marginLeft: 16,
    justifyContent: 'center',
  },
  btnTxt: {
    textAlign: 'center',
    color: '#FFF',
    fontSize: 16,
    fontWeight: '500',
  },
  intro: {
    padding: 24,
    fontSize: 16,
    lineHeight: 24,
    color: '#80849D',
    paddingBottom: 25,
  },
});
export default styles;
