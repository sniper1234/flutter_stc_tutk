#ifndef _UTILS_INCLUDE_
#define _UTILS_INCLUDE_

#include <iostream>
#include <sstream>
#include <ctype.h>
#include <string>

#if defined(_MSC_VER)
#if !defined(WINCE) && defined(__STDC_SECURE_LIB__) && _MSC_VER >= 1500 // VC++ 9.0 and above 
#define snprintf sprintf_s
#elif _MSC_VER >= 1900 // VC++ 14.0 and above
#define snprintf std::snprintf
#else
#define snprintf _snprintf
#endif
#elif defined(__ANDROID__) || defined(__QNXNTO__)
#define snprintf snprintf
#elif __cplusplus >= 201103L
#if !defined(__MINGW32__) && !defined(__CYGWIN__)
#define snprintf std::snprintf
#endif
#endif

namespace Utils {

#define NO_ASSIGNMENT(X) \
    X& operator=(const X&);

#define NO_COPYABLE(X) \
    X& operator=(const X&);\
    X(const X&);


    //?бщ????assert???йW
    template <bool> struct STATIC_ASSERTION_FAILURE;
    template <> struct STATIC_ASSERTION_FAILURE<true> { enum { value = 1 }; };
    template<uint32_t> struct static_assert_test {};

#define UTIL_JOIN(P,A) P##A
    //????boost??assert
#define UTILS_STATIC_ASSERT( B ) \
typedef Utils::static_assert_test<\
sizeof(Utils::STATIC_ASSERTION_FAILURE< (bool)( B ) >)> \
UTIL_JOIN(boost_static_assert_typedef_ , __LINE__)

    /** ???????????бщ????????????
    */
    //????????????????????json????????????
    template<typename T>struct TypeSize;
    template<> struct TypeSize<int8_t> { enum { SIZE = sizeof(int8_t) }; };
    template<> struct TypeSize<uint8_t> { enum { SIZE = sizeof(uint8_t) }; };
    template<> struct TypeSize<int16_t> { enum { SIZE = sizeof(int16_t) }; };
    template<> struct TypeSize<uint16_t> { enum { SIZE = sizeof(uint16_t) }; };
    template<> struct TypeSize<int32_t> { enum { SIZE = sizeof(int32_t) }; };
    template<> struct TypeSize<uint32_t> { enum { SIZE = sizeof(uint32_t) }; };
    template<> struct TypeSize<int64_t> { enum { SIZE = sizeof(int64_t) }; };
    template<> struct TypeSize<uint64_t> { enum { SIZE = sizeof(uint64_t) }; };
    template<> struct TypeSize<float> { enum { SIZE = sizeof(float) }; };
    template<> struct TypeSize<double> { enum { SIZE = sizeof(double) }; };

    /** ?????????????????бщ???????????????????????????????????????????бщ????
    *   ???????????бщ??
    */
    template<typename T>
    void toBigEndian(const T &val, unsigned char *out)
    {
        UTILS_STATIC_ASSERT(TypeSize<T>::SIZE);
#ifdef BIG_ENDIAN
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   out[i] = ((char*)&val)[i]; }
#else
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   out[sizeof(T) - i - 1] = ((char*)&val)[i]; }
#endif
    }

    template<typename T>
    void toLittleEndian(const T &val, unsigned char *out)
    {
        UTILS_STATIC_ASSERT(TypeSize<T>::SIZE);
#ifdef BIG_ENDIAN
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   out[i] = ((char*)&val)[sizeof(T) - i - 1]; }
#else
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   out[i] = ((char*)&val)[i]; }
#endif
    }

    template<typename T>
    T BigEndianToTypeValue(const unsigned char* in)
    {
        T ret = 0;
        UTILS_STATIC_ASSERT(TypeSize<T>::SIZE);
#ifdef BIG_ENDIAN
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   ((char*)&ret)[i] = in[i];    }
#else
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   ((char*)&ret)[i] = in[sizeof(T) - i - 1];    }
#endif
        return ret;
    }

    template<typename T>
    T LittleEndianToTypeValue(const unsigned char* in)
    {
        T ret = 0;
        UTILS_STATIC_ASSERT(TypeSize<T>::SIZE);
#ifdef BIG_ENDIAN
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   ((char*)&ret)[i] = in[sizeof(T) - i - 1];    }
#else
            for (uint32_t i = 0; i<sizeof(T); i++)
            {   ((char*)&ret)[i] = in[i];    }
#endif
        return ret;
    }

    //????????????????????
    template<uint32_t>
    class BitReverseOnSize;

    template<>
    class BitReverseOnSize<sizeof(uint8_t)> {
    public:
        template<typename T>
        static T reverse(T in)
        {
            UTILS_STATIC_ASSERT(sizeof(T) == sizeof(uint8_t));
            UTILS_STATIC_ASSERT(1 == sizeof(uint8_t));
            uint8_t bits = static_cast<uint8_t>(in);
            /**??????????4????????????????4??????2????????????????2????????????????????????????
            */
            bits = ((bits >> 4) | (bits << 4));
            bits = ((bits << 2) & 0xcc) | ((bits >> 2) & 0x33);
            bits = ((bits << 1) & 0xAA) | ((bits >> 1) & 0x55);
            return static_cast<T>(bits);
        }
    };

      namespace implements {

    template<typename T>
    struct void_type_is_not_valid_for_unique_ptr{
       enum {valid=1};
    };
    template<>
    struct void_type_is_not_valid_for_unique_ptr<void>{
       enum {valid=0};
    };

    struct type_free {
        virtual ~type_free(){}
        virtual void free_type(void*) = 0;
    };

    template<typename T>
    struct func_signature{
        typedef void (*signature)(T*);
        typedef T type;
    };

    template<typename T, typename D>
    struct type_free_free : public type_free{
        type_free_free(typename implements::func_signature<D>::signature d) :deleter(d)
        {}
        void free_type(void* ptr) {
            if (ptr) {
                deleter(static_cast<typename implements::func_signature<D>::type*>(ptr));
            }
        }
    private:
        typename implements::func_signature<D>::signature deleter;
    };

    template<typename T>
    struct type_free_delete : public type_free{
        void free_type(void* ptr) {
            delete ((T*)ptr);
        }
    };

    
    /** ???йW?????гд?????йW??йW??йW??гд????????йW?????unique???????????????йW????????????????????гд??гд??????????????гд???????????гд??free???гд??гд???????????
    */
    /*deleter*/
    template<typename T>
    struct unique_free_ptr {
        unique_free_ptr(T* ptr,type_free* d) :type_ptr(ptr), deleter(d)
        {}

        ~unique_free_ptr() {
            if(0!=type_ptr)
            {
                deleter->free_type(type_ptr);
                type_ptr = 0;
            }
            delete deleter;
        }
        T* get() {
            return type_ptr;
        }
        const T* get() const {
            return type_ptr;
        }
        T* operator->() {
            return type_ptr;
        }
        const T* operator->() const {
            return type_ptr;
        }
        T& operator*() {
            return *type_ptr;
        }
        const T& operator*() const {
            return *type_ptr;
        }
        T* release() {
            T* ret = type_ptr;
            type_ptr = 0;
            return ret;
        }
        T* reset(T* ptr)
        {
            deleter->free_type(type_ptr);
            type_ptr = ptr;
            return type_ptr;
        }
        unique_free_ptr(unique_free_ptr& another)
            : type_ptr(another.type_ptr),deleter(another.deleter)
        {
            another.type_ptr = 0;
            another.deleter = 0;
        }
        unique_free_ptr& operator=(unique_free_ptr& another)
        {
            this->~unique_free_ptr();
            type_ptr = another.type_ptr,deleter = another.deleter;
            another.type_ptr = 0;
            another.deleter = 0;
            return *this;
        }
    private:
        T* type_ptr;
        type_free* deleter;
    };
}//end namespace

    template<typename T,typename D=T>
    struct unique_ptr : public implements::unique_free_ptr<T>{
        unique_ptr(T* ptr,typename implements::func_signature<D>::signature d)
            : implements::unique_free_ptr<T>(ptr,new implements::type_free_free<T, D>(d))
        {}
        template<typename CT>
        unique_ptr(CT* ptr, typename implements::func_signature<D>::signature d)
            : implements::unique_free_ptr<T>(static_cast<T*>(ptr),new implements::type_free_free<T, D>(d)) //type CT must convertble to type T
        {UTILS_STATIC_ASSERT(implements::void_type_is_not_valid_for_unique_ptr<CT>::valid);}
        unique_ptr(T* ptr)
            : implements::unique_free_ptr<T>(ptr,new implements::type_free_delete<T>())
        {}
        template<typename CT>
        unique_ptr(CT* ptr)
            : implements::unique_free_ptr<T>(static_cast<T*>(ptr),new implements::type_free_delete<T>()) //type CT must convertble to type T
        {UTILS_STATIC_ASSERT(implements::void_type_is_not_valid_for_unique_ptr<CT>::valid);}

        unique_ptr(unique_ptr& another)
            : implements::unique_free_ptr<T>(another)
        {}
        unique_ptr& operator=(unique_ptr& another)
        {
            implements::unique_free_ptr<T>::operator=(another);
            return *this;
        }
    };

    template<typename T>
    class AutoReleaser{
    public:
        typedef void (*Releaser)(T);
        AutoReleaser(Releaser r,T rd): releaser(r),released(rd)
        {}
        ~AutoReleaser()
        {
            releaser(released);
        }
    private:
        Releaser releaser;
        T released;
    };

    template<>
    class AutoReleaser<void>{
    public:
        typedef int (*Releaser)(void);
        AutoReleaser(Releaser r): releaser(r)
        {}
        ~AutoReleaser()
        {
            releaser();
        }
    private:
        Releaser releaser;
    };

    /** ????????????
        lessThan?????? ==0 l????r??<0 l????r??>0 l????r
    */
    template<typename T>
    const T* BinaryFind(const T* first
                           ,const T* last
                           ,const T* key
                           ,int (*lessThan)(const T* l,const T* r))
    {
        while(first <= last)
        {
            const uint32_t num = (last-first)/2;
            const T* mid = first+num;

            int ret = lessThan(mid,key);
            if(ret > 0)
                last = mid -1;
            else if(ret < 0)
                first = mid+1;
            else{
                return mid;
            }
        }
        return 0;
    }

    /** ???????бъ??
    */
    template<typename T1,typename T2>
    struct pair{
        pair(T1 t1,T2 t2):first(t1),second(t2)
        {}
        T1 first;
        T2 second;
    };
    template<typename T1,typename T2>
    pair<T1,T2> make_pair(T1 t1,T2 t2)
    {
        return pair<T1,T2>(t1,t2);
    }
    
    /** ?????????? **/
    template<typename T>
    std::string toString(const T& val,int base=10)
    {
        char buff[65] = {0};
        switch(base){
        case 2 :
        {
            T tVal = val;
            for(size_t i=sizeof(T)*8;i>0;--i)
            {
                buff[i-1] = (tVal&0x01) + '0';
                tVal >>= 1;
            }
        }
        break;
        case 8: {const char* fmt = sizeof(val) > 4 ? "%llo" : "%o"; snprintf(buff, sizeof(buff), fmt, val); } break;
        case 10: {const char* fmt = sizeof(val) > 4 ? "%lld" : "%d"; snprintf(buff, sizeof(buff), fmt, val); } break;
        case 16: {const char* fmt = sizeof(val) > 4 ? "%llX" : "%X"; snprintf(buff, sizeof(buff), fmt, val); } break;
        default : break;
        }
        return std::string((const char*)buff);
    }

    // Special versions for floats/doubles.
    template<> inline std::string toString<double>(const double& t,int base) {
        char buff[65] = { 0 };
        snprintf(buff,sizeof(buff),"%g",t);
        return std::string((const char*)buff);
    }

    template<> inline std::string toString<float>(const float& t,int base) {
      return toString(static_cast<double>(t), base);
    }

    template<> inline std::string toString<bool>(const bool& b,int base) {
        if(b){
            return "true";
        }else{
            return "false";
        }
    }
    
    template<> inline std::string toString<std::string>(const std::string& s,int base) {
        return s;
    }

    template<typename T>
    T StringTo(const std::string& str,int base=10){
        UTILS_STATIC_ASSERT(TypeSize<T>::SIZE);

        if(2==base){
            T ret = 0;
            const size_t msize = sizeof(T)*8<str.size() ? sizeof(T)*8 : str.size();
            for(size_t i=0;i<msize;++i)
            {
                ret <<= 1;
                if('0'==str[i]){
                    ret |= 0x00;
                }else{
                    ret |= 0x01;
                }
            }
            return ret;
        }else{
#ifdef _MSC_VER
            return static_cast<T>(_strtoui64(str.c_str(), NULL, base));
#else
            return static_cast<T>(strtoull(str.c_str(), NULL, base));
#endif
        }
    }
    template<>
    inline std::string StringTo<std::string>(const std::string& str,int base){
        return str;
    }
    template<>
    inline bool StringTo<bool>(const std::string& str,int base){
        if(str.size()>0)
        {
            return 't'==str[0] || 'T'==str[0] || '1'==str[0];
        }
        return false;
    }

    inline char Hex2Char(uint8_t hex)
    {
        if(hex<10){
            return '0'+hex;
        }else{
            return 'A'+(hex-10);
        }
    }
    inline uint8_t Char2Hex(char ch)
    {
        ch = toupper(ch);
        if(ch<='9'){
            return (uint8_t)(ch-'0');
        }else{
            return (uint8_t)(ch-'A'+10);
        }
    }
    inline char Dec2Char(uint8_t dec)
    {
        return dec+'0';
    }
    inline uint8_t Char2Dec(char ch)
    {
        return ch-'0';
    }

    inline bool isDec(char ch)
    {
        return ch>='0' && ch<= '9';
    }
    inline bool isHex(char ch)
    {
        ch = toupper(ch);
        return isDec(ch) || (ch>='A' && ch<='F');
    }

    inline std::string ConcanateDir(const std::string& dir,const char* file)
    {
        if(0==dir.size())
        {
            return file;
        }
        
        std::string ret = dir;
        if('\\'!=dir[dir.size()-1] && '/'!=dir[dir.size()-1])
        {
            ret += '/';
        }
        while( ('\\'==*file || '/'==*file) && 0!=*file){
            ++file;
        }
        if(0==*file)
        {
            return ret;
        }
        return ret+=file;
    }
}//namespace Utils
#endif
