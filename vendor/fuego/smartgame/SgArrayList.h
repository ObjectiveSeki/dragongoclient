//----------------------------------------------------------------------------
/** @file SgArrayList.h
    Static list. */
//----------------------------------------------------------------------------

#ifndef SG_ARRAYLIST_H
#define SG_ARRAYLIST_H

#include <algorithm>

//----------------------------------------------------------------------------

/** Static list not using dynamic memory allocation.
    Elements need to have a default constructor.
    They should be value-types, not entity-types, because operations like
    Clear() do not call the destructor of the old elements immediately. */
template<typename T, int SIZE>
class SgArrayList
{
public:
    /** Const iterator */
    class Iterator
    {
    public:
        Iterator(const SgArrayList& list);

        const T& operator*() const;

        void operator++();

        operator bool() const;

    private:
        const T* m_end;

        const T* m_current;
    };

    /** Non-const iterator */
    class NonConstIterator
    {
    public:
        NonConstIterator(SgArrayList& list);

        T& operator*() const;

        void operator++();

        operator bool() const;

    private:
        const T* m_end;

        T* m_current;
    };

    SgArrayList();

    /** Construct list with one element. */
    explicit SgArrayList(const T& val);

    SgArrayList(const SgArrayList<T,SIZE>& list);

    SgArrayList& operator=(const SgArrayList& list);

    bool operator==(const SgArrayList& list) const;

    bool operator!=(const SgArrayList& list) const;

    T& operator[](int index);

    const T& operator[](int index) const;

    void Clear();

    bool Contains(const T& val) const;

    /** Remove first occurrence of a value.
        Like RemoveFirst, but more efficient and does not preserve
        order of remaining elements. The first occurrence of the value is
        replaced by the last element.
        @return false, if element was not found */
    bool Exclude(const T& val);

    /** PushBack value at the end of the list if it's not already in the
        list. */
    void Include(const T& val);

    /** Build intersection with other list.
        List may not contain duplicate entries. */
    SgArrayList Intersect(const SgArrayList<T,SIZE>& list) const;

    bool IsEmpty() const;

    T& Last();

    const T& Last() const;

    int Length() const;

    /** Remove the last element of the list.
        Does not return the last element for efficiency. To get the last
        element, use Last() before calling PopBack(). */
    void PopBack();

    void PushBack(const T& val);

    /** Push back all elements of another list.
        Works with lists of different maximum sizes.
        Requires: Total resulting number of elements will fit into the target
        list. */
    template<int SIZE2>
    void PushBackList(const SgArrayList<T,SIZE2>& list);

    /** Remove first occurence of a value.
        Preserves order of remaining elements.
        @see Exclude */
    void RemoveFirst(const T& val);

    /** Resize list.
        If new length is greater than current length, then the elements
        at a place greater than the old length are not initialized, they are
        just the old elements at this place.
        This is necessary if elements are re-used for efficiency and will be
        initialized later. */
    void Resize(int length);

    bool SameElements(const SgArrayList& list) const;

    void SetTo(const T& val);

    void Sort();

private:
    friend class Iterator;
    friend class NonConstIterator;

    int m_len;

    T m_array[SIZE];
};

//----------------------------------------------------------------------------

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::Iterator::Iterator(const SgArrayList& list)
    : m_end(list.m_array + list.Length()),
      m_current(list.m_array)
{
}

template<typename T, int SIZE>
inline const T& SgArrayList<T,SIZE>::Iterator::operator*() const
{
    SG_ASSERT(*this);
    return *m_current;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::Iterator::operator++()
{
    ++m_current;
}

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::Iterator::operator bool() const
{
    return m_current < m_end;
}

template<typename T, int SIZE>
inline
SgArrayList<T,SIZE>::NonConstIterator::NonConstIterator(SgArrayList& list)
    : m_end(list.m_array + list.Length()),
      m_current(list.m_array)
{
}

template<typename T, int SIZE>
inline T& SgArrayList<T,SIZE>::NonConstIterator::operator*() const
{
    SG_ASSERT(*this);
    return *m_current;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::NonConstIterator::operator++()
{
    ++m_current;
}

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::NonConstIterator::operator bool() const
{
    return m_current < m_end;
}

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::SgArrayList()
    : m_len(0)
{
}

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::SgArrayList(const T& val)
{
    SetTo(val);
    m_len = 1;
    m_array[0] = val;
}

template<typename T, int SIZE>
inline SgArrayList<T,SIZE>::SgArrayList(const SgArrayList<T,SIZE>& list)
{
    *this = list;
}

template<typename T, int SIZE>
SgArrayList<T,SIZE>& SgArrayList<T,SIZE>::operator=(const SgArrayList& list)
{
    m_len = list.m_len;
    T* p = m_array;
    const T* pp = list.m_array;
    for (int i = m_len; i--; ++p, ++pp)
        *p = *pp;
    return *this;
}

template<typename T, int SIZE>
bool SgArrayList<T,SIZE>::operator==(const SgArrayList& list) const
{
    if (m_len != list.m_len)
        return false;
    const T* p = m_array;
    const T* pp = list.m_array;
    for (int i = m_len; i--; ++p, ++pp)
        if (*p != *pp)
            return false;
    return true;
}

template<typename T, int SIZE>
inline bool SgArrayList<T,SIZE>::operator!=(const SgArrayList& list) const
{
    return ! this->operator==(list);
}

template<typename T, int SIZE>
inline T& SgArrayList<T,SIZE>::operator[](int index)
{
    SG_ASSERT(index >= 0);
    SG_ASSERT(index < m_len);
    return m_array[index];
}

template<typename T, int SIZE>
inline const T& SgArrayList<T,SIZE>::operator[](int index) const
{
    SG_ASSERT(index >= 0);
    SG_ASSERT(index < m_len);
    return m_array[index];
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::Clear()
{
    m_len = 0;
}

template<typename T, int SIZE>
bool SgArrayList<T,SIZE>::Contains(const T& val) const
{
    int i;
    const T* t = m_array;
    for (i = m_len; i--; ++t)
        if (*t == val)
            return true;
    return false;
 }

template<typename T, int SIZE>
bool SgArrayList<T,SIZE>::Exclude(const T& val)
{
    // Go backwards through list, because with game playing programs
    // it is more likely that a recently added element is removed first
    T* t = m_array + m_len - 1;
    for (int i = m_len; i--; --t)
        if (*t == val)
        {
            --m_len;
            if (m_len > 0)
                *t = *(m_array + m_len);
            return true;
        }
    return false;
}

template<typename T, int SIZE>
void SgArrayList<T,SIZE>::Include(const T& val)
{
    if (! Contains(val))
        PushBack(val);
}

template<typename T, int SIZE>
SgArrayList<T,SIZE>
SgArrayList<T,SIZE>::Intersect(const SgArrayList<T,SIZE>& list) const
{
    SgArrayList<T, SIZE> result;
    const T* t = m_array;
    for (int i = m_len; i--; ++t)
        if (list.Contains(*t))
        {
            SG_ASSERT(! result.Contains(*t));
            result.PushBack(*t);
        }
    return result;
}

template<typename T, int SIZE>
inline bool SgArrayList<T,SIZE>::IsEmpty() const
{
    return m_len == 0;
}

template<typename T, int SIZE>
inline T& SgArrayList<T,SIZE>::Last()
{
    SG_ASSERT(m_len > 0);
    return m_array[m_len - 1];
}

template<typename T, int SIZE>
inline const T& SgArrayList<T,SIZE>::Last() const
{
    SG_ASSERT(m_len > 0);
    return m_array[m_len - 1];
}

template<typename T, int SIZE>
inline int SgArrayList<T,SIZE>::Length() const
{
    return m_len;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::PopBack()
{
    SG_ASSERT(m_len > 0);
    --m_len;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::PushBack(const T& val)
{
    SG_ASSERT(m_len < SIZE);
    m_array[m_len++] = val;
}

template<typename T, int SIZE>
template<int SIZE2>
inline void SgArrayList<T,SIZE>::PushBackList(const SgArrayList<T,SIZE2>& list)
{
    for (typename SgArrayList<T,SIZE2>::Iterator it(list); it; ++it)
        PushBack(*it);
}

template<typename T, int SIZE>
void SgArrayList<T,SIZE>::RemoveFirst(const T& val)
{
    int i;
    T* t = m_array;
    for (i = m_len; i--; ++t)
        if (*t == val)
        {
            for ( ; i--; ++t)
                *t = *(t + 1);
            --m_len;
            break;
        }
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::Resize(int length)
{
    SG_ASSERT(length >= 0);
    SG_ASSERT(length <= SIZE);
    m_len = length;
}

template<typename T, int SIZE>
bool SgArrayList<T,SIZE>::SameElements(const SgArrayList& list) const
{
    if (m_len != list.m_len)
        return false;
    const T* p = m_array;
    for (int i = m_len; i--; ++p)
        if (! list.Contains(*p))
            return false;
    return true;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::SetTo(const T& val)
{
    m_len = 1;
    m_array[0] = val;
}

template<typename T, int SIZE>
inline void SgArrayList<T,SIZE>::Sort()
{
    std::sort(m_array, m_array + m_len);
}

//----------------------------------------------------------------------------

#endif // SG_ARRAYLIST_H
